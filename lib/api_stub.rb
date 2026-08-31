class Lyricast::RemoteSettings

	def log_in
	end

	def settings
		JSON.load_file 'tmp/remote_config.json', symbolize_names: true
	end

end
