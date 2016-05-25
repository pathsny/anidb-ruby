require 'daybreak'

class ModelDB
  class << self
    def create_db
      data_location = File.join(File.dirname(__FILE__), '../../data')
      Daybreak::DB.new(File.join(data_location, 'shows.db')). tap do |db|
        at_exit do 
          puts "closing database"
          unless db.closed?
            thr = Thread.new { db.flush.close }
            thr.join
          end      
        end
      end
    end  

    def get_db
      @db ||= create_db
      @db.lock {
        yield @db
      }
    end
  end
end      


module Model
  def self.included(base)
    base.extend(ClassMethods)
    base.instance_variable_set(:@model_key, base.name.downcase + '_')
  end
  
  module ClassMethods
    private
    attr_reader :current_version

    def is_key_of_model?(k) #bool
      k.start_with?(@model_key)
    end

    def make_key(id)
      @model_key + id.to_s
    end  

    def configure_model(options) # marshal
      self.instance_variable_set(:@current_version, options[:version])
      self.include(Veto.model(options[:validator].new))

      var_list = options[:marshal_fields].map {|f| "@#{f}"}.join(',')

      self.class_eval("def marshal_dump; [#{var_list}]; end")
      self.class_eval("def marshal_load(dump); #{var_list} = dump; @is_new = false; end")
    end  

    public 
    def all
      ModelDB.get_db do |db| 
        db.select {|k, v| is_key_of_model?(k) }.map{|k, v| v} 
      end  
    end
    
    def get(id)
      ModelDB.get_db do |db|
        db[make_key(id)].tap { |s| raise "invalid id" unless s }
      end  
    end

    def exists?(id)
      ModelDB.get_db do |db|
        db.has_key?(make_key(id))
      end  
    end  
  end

  private
    def current_version
      self.class.send(:current_version)
    end

    def make_key(id)
      self.class.send(:make_key, id)
    end

  public

  attr_reader :created_at, :updated_at    

  def initialize
    @is_new = true
    @version = current_version
  end

  def is_new?
    @is_new
  end

  def has_instance_in_db?
    return false unless self.id
    self.class.exists?(self.id)
  end  

  def save
    validate!
    ModelDB.get_db do |db|
      @created_at = DateTime.now if self.is_new?
      @is_new = false
      @updated_at = DateTime.now
      db[make_key(id)] = self
    end
  end

  def destroy
    ModelDB.get_db do |db|
      db.delete(make_key(self.id))
    end  
  end
end  