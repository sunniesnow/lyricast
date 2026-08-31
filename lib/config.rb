module Lyricast::Config
	CONFIG_DIR = ENV.fetch 'LYRICAST_CONFIG_DIR', 'config'
	PROJECT_ID = ENV['LYRICAST_PROJECT_ID'] || raise('Must set LYRICAST_PROJECT_ID in env var')
	DATA_DIR = ENV.fetch 'LYRICAST_DATA_DIR', 'data'
	CACHE_SECONDS = (ENV.fetch 'LYRICAST_CACHE_SECONDS', '600').to_i
	INSTANCE_ID = ENV.fetch 'LYRICAST_INSTANCE_ID', 'lyricast'

	def self.sheet name
		YAML.load_file(File.join(CONFIG_DIR, "#{name}Sheet.asset"), symbolize_names: true)[:MonoBehaviour][:dataArray].freeze
	end
end
