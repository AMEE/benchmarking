module AMEE

  class Search < AMEE::Collection
    def initialize(connection,options={})
      @use_v3_connection = true
      @matrix||=options.delete :matrix
      @matrix||='wikiDoc'
      @term=options[:term]
      super(connection,options)
    end
    attr_reader :matrix
    def klass
      Result
    end
    def collectionpath
      "/#{AMEE::Connection.api_version}/search;#{matrix}"
    end

    def jsoncollector
      @doc['Results']
    end
    def xmlcollectorpath
      '/Representation/Results/*'
    end

    def parse_json(p)
      data = {}
    end
    def parse_xml(p)
      Result.parse_xml(p)
    end

    class Result < AMEE::Object
      def initialize(options={})
        @data=options
        @connection=options[:connection]
        @type=options[:type]
        super
      end
      def self.parse_xml(p)
        data = {}
        data[:uid] = x '@uid',:doc=>p
        data[:type] = x('name()',:doc=>p).to_s
        data[:path] = x 'FullPath',:doc=>p
        data[:meta]={ :wikidoc => (x 'WikiDoc',:doc=>p) }
        data[:name]=x 'Name', :doc=>p
        case data[:type]
        when "Category" then
          data[:meta][:provenance] = (x 'Provenance',:doc=>p)
          data[:meta][:authority] = (x 'Authority',:doc=>p)
          data[:meta][:wikiname] = (x 'WikiName',:doc=>p)
          data[:meta][:tags] = (x 'Tags/Tag/Tag',:doc=>p)
          data[:itemdef] = (x 'ItemDefinition/@uid',:doc=>p)
        when "Item" then
          data[:label] = x 'Label', :doc =>p
          paths=[x('Values/Value/Path',:doc=>p)].flatten
          values=[x('Values/Value/Value',:doc=>p)].flatten
          histories=[x('Values/Value/@history',:doc=>p)].flatten
          data[:values]=paths.zip(values, histories).map{
            |x| {:value=>x[1],:path=>x[0],:has_history=>(x[2]=='true')}
          } if paths
        end
        data
      end
      def self.from_xml(p)
        Result.new(Result.parse_xml(p))
      end
      def resulttype
        case @type
        when "Category" then Data::Category
        when "Item" then Data::Item
        end
      end
      attr_accessor :data
      attr_reader :connection
      def connection=(val)
        @connection=val
        data[:connection]=val
      end
      def result
        resulttype.new(@data)
      end

    end

    class WithinCategory < Search
      def initialize(connection,options={})
        @wikiname=options.delete :wikiname
        @matrix=options.delete :matrix
        @matrix||='full'
        super(connection,options)
      end

      attr_reader :wikiname,:matrix
      
      def collectionpath
        "/#{AMEE::Connection.api_version}/categories/#{wikiname}/items;#{matrix}"
      end

      def jsoncollector
        @doc['Results']
      end
      
      def xmlcollectorpath
        '/Representation/Items/*'
      end
      
    end

  end
 
end