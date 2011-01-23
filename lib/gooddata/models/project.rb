module GoodData
  class Project
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'

    attr_accessor :connection

    def initialize(connection, json)
      @connection = connection
      @json = json
    end

    def save
      response = @connection.post PROJECTS_PATH, { 'project' => @json }
      if uri == nil
        response = @connection.get response['uri']
        @json = response['project']
      end
    end

    def delete
      raise "Project '#{name}' with id #{uri} is already deleted" if state == :deleted
      @connection.delete @json['links']['self']
    end

    def uri
      @json['links']['self'] if @json['links'] && @json['links']['self']
    end

    def name
      @json['meta']['title'] if @json['meta']
    end

    def state
      @json['content']['state'].downcase.to_sym if @json['content'] && @json['content']['state']
    end

    def md
      unless @md
        @md = Metadata.new @connection.get @json['links']['metadata']
      end
      @md
    end

    def slis
      link = "#{@json['links']['metadata']}#{SLIS_PATH}"
      Metadata.new @connection.get link
    end

    def datasets
      unless @datasets
        datasets_uri  = "#{md['data']}/sets"
        response      = @connection.get datasets_uri
        dataset_array = response['dataSetsInfo']['sets'].map do |ds|
          Dataset.remote @connection, ds
        end
        @datasets = Datasets.new self, dataset_array
      end
      @datasets
    end

    def to_json
      @json
    end
  end
end