#-------------------------------------------------------------------------------
# Winnow.  A supervised learning algorithm which classifies based on a 
# linear threshold rule.  Originally described and implemented by 
# Nick Littlestone in "Learning Quickly When Irrelevant Attributes Abound: A 
# New Linear-Threshold Algorithm."  Machine Learning. 2(4), 285-318. 1988.
#-------------------------------------------------------------------------------
# This file contains the Winnow class, WekaCompatability module, 
# Instance class, and Model class.
#-------------------------------------------------------------------------------
# originally implemented by Matt Linnell, updated/edited by Chris Miller - Dec 2009
#


#-------------------------------------------------------------------------------
# This module provides compatability with Weka specific constructs, such as an ARFF file
#-------------------------------------------------------------------------------
module WekaCompatability
    #---------------------------------------------------------------------------
    # Loads ARFF format file for use in building model.  The ARFF format is 
    # described by the Weka standard, http://www.cs.waikato.ac.nz/ml/weka/.  This
    # method will return the feature_list, the two classes, and an array of instances
    #   file = String or File object
    #---------------------------------------------------------------------------
    def load_arff( file )
        # If not given file, open file
        file = File.open( file ) unless file.class == File
        # First line is descriptor, we don't do anything with that (yet)
        file.readline
        # The following lines are the attribute descriptors
        # They look like this: @attribute(space)sunny_day(space){0,1}\n
        feature_list = []
        file.each_line{ |line| feature_list.push( line.strip.split(" ")[1,2] ); break if line.split(" ")[1] == "class" }
        t_class, f_class = feature_list.pop[1][1..-2].split( "," )
        # Now, load up training data/instances
        instances = []
        tmp = false
        file.each_line{ |line|
            next if line.strip.size == 0
            if tmp
                binary_vector = line.strip.split(",")
                classified = binary_vector.pop == "true" ? true : false
                binary_vector.map!{ |ii| ii = ii == "1" ? true : false } # convert string to binary vals
                instances.push( Instance.new( binary_vector , classified ) ) 
            end
            tmp = true if line.strip == "@data"
        }
        return feature_list, t_class, f_class, instances
    end
end

#-------------------------------------------------------------------------------
# This class represents a single sample in feature space (binary vector)
# Can (but does not have to) have the known class for this sample
# It is simply an array with a "classified" attribute for this instance's class
# The array is binary in nature, so all elements are either true or false
#-------------------------------------------------------------------------------

class Instance < Array
    attr_accessor :is_class
    def initialize( arr = nil, is_class=false )
        super()
        self.push( *arr ) unless arr.nil?
        @is_class = is_class 
    end
end

#-------------------------------------------------------------------------------
# This class represents a model of our Winnow Classifier.  It contians 4
# attributes:
#   true_class  = The name (ie Sunny Day) of the true class
#   false_class = The name (ie Rainy Day) of the false class
#   attributes  = An array of attribute names. [ "was cloudy yesterday", "is above > 80 degrees", etc ]
#   weights     = An array of weights associated with each feature in the attribute vector.  
#                 They must be in same order, so [ 1, 0 ] means it was cloudy yesterday but not above 80 degrees
#-------------------------------------------------------------------------------
class Model
    attr_accessor :true_class, :false_class, :attributes, :weights

    def to_s
        attributes.each_index{ |ii| puts attributes[ii][0] + "\t" + weights[ii].to_s }
    end
end

#-------------------------------------------------------------------------------
# This is the actuall Winnow classifier.  
#-------------------------------------------------------------------------------
class Winnow
    include WekaCompatability

    attr_accessor :threshold, :alpha, :beta
    attr_reader :default_weight, :model

    #---------------------------------------------------------------------------
    # Inititializes the Winnow instance
    #   alpha = Promotion factor
    #   beta  = Demotion factor
    #   default_weights = Initial weight for each feature/attribute
    #---------------------------------------------------------------------------
    def initialize( alpha=2.0, beta=0.5, default_weight=2.0 )
        @model = Model.new
        @alpha = alpha
        @beta  = beta
        @default_weight = default_weight
    end

    #---------------------------------------------------------------------------
    # Using the WekaCompatability mixin, load and instatiate trained model from ARFF file
    #   file = The path/name of the file OR the File IO object
    #---------------------------------------------------------------------------
    def initialize_from_arff( file )
        feature_list, t_class, f_class, instances = WekaCompatability.load_arff( file )
        initialize_model( feature_list, t_class, f_class )
        train_model( instances )
    end

    #---------------------------------------------------------------------------
    # Set the feature space structure for this model and initialize weights.
    #   feature_list = An array of feature names, must be same order as the 
    #                  features are in the encoded feature space
    #   true_class   = The name of the true class (ie Cloudy )
    #   false_class  = The name of the false class (ie Sunny )
    #---------------------------------------------------------------------------
    def initialize_model( feature_list, true_class=true, false_class=false, instances=nil )
        @model.true_class, @model.false_class = true_class, false_class
        @model.attributes = feature_list
        @model.weights = Array.new( feature_list.size){ @default_weight }

        # Set threshold
        # In Weka's Winnow implementation, this is equal to # attributes - 1
        @threshold = @model.attributes.size - 1
    end

    #---------------------------------------------------------------------------
    # Trains a classifier based on the given training data
    #   instances = An array of instances OR a single instance
    #---------------------------------------------------------------------------
    def train_model( instances )
        instances = [ instances ] unless instances.class == Array
        # First randomize data **TODO** Use GSL for ranomization
        instances.sort!{ |xx,yy| rand(3) + 1 }
        # Step through each instance.
        instances.each do |inst|
            # First, predict based on current weights
            sum = score( inst )
            # Now, if we predict incorrectly, then we need to adjust weights
            if sum > @threshold
                # Fix weights for false positives
                demote!( inst ) if !inst.is_class
            else
                # Fix weights for false negatives
                promote!( inst ) if inst.is_class
            end
        end
        instances.push( *instances )
    end

    #---------------------------------------------------------------------------
    # Classify instance based on current model.  An instance is classified as TRUE
    # if the sum of the represented feature weights (only features present in this
    # instance) is greater than the threshold.
    #   instance = instance/sample to classify
    #---------------------------------------------------------------------------
    def classify_instance( instance )
        return score(instance) > threshold ? true : false
    end


    private

    #---------------------------------------------------------------------------
    # Score the given instance based on the current model
    #---------------------------------------------------------------------------
    def score( instance )
        # Sum weights of all features labeled as TRUE
        sum = 0.0
        instance.each_index{ |jj| sum += @model.weights[jj] if instance[jj] }
        return sum
    end

    #---------------------------------------------------------------------------
    # Promote the current model weights based on the given instance.
    #---------------------------------------------------------------------------
    def promote!( instance )
        # STDERR.puts "Promoting: old weights => #{@model.weights.join(",")}"
        # For every feature/attribute present, promote the corresponding weight
        instance.each_index{ |ii| @model.weights[ii] *= @alpha if instance[ii] }
        #STDERR.puts "\tnew weights => #{@model.weights.join(",")}"
    end

    #---------------------------------------------------------------------------
    # Demote the current model weights based on the given instance.
    #---------------------------------------------------------------------------
    def demote!( instance )
        #STDERR.puts "Demoting: old weights => #{@model.weights.join(",")}"
        # For every feature/attribute present, demote the corresponding weight
        instance.each_index{ |ii| @model.weights[ii] *= @beta if instance[ii] }
        #STDERR.puts "\t\tnew weights => #{@model.weights.join(",")}"
    end
end
