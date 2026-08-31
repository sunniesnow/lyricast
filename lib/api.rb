# Note: does not have thread safety!
class Lyricast::RemoteSettings

	PLAYER_AUTH_ENDPOINT = URI 'https://player-auth.services.api.unity.com/v1/'
	CONFIG_ENDPOINT = URI 'https://config.services.api.unity.com/'

	def initialize project_id = Lyricast::Config::PROJECT_ID, data_dir = Lyricast::Config::DATA_DIR
		@project_id = project_id
		@data_dir = data_dir
		@login_path = File.join @data_dir, 'login'
		@installation_id_path = File.join @data_dir, 'installation-id'
		FileUtils.mkdir_p @data_dir
	end

	def log_in
		begin
			login = JSON.load_file @login_path, symbolize_names: true
		rescue Errno::ENOENT
			new_anonymous
			return
		end
		@session_token = login[:sessionToken]
		refresh_token
	end

	def post_player_auth path, **payload
		payload = JSON.generate payload
		headers = {
			'ProjectId' => @project_id,
			'UnityEnvironment' => 'production',
			'Error-Version' => 'v1',
			'Content-Type' => 'application/json',
		}
		res = Net::HTTP.post PLAYER_AUTH_ENDPOINT + path, payload, headers
		res.value # raises error if not 200
		JSON.parse res.body, symbolize_names: true
	end

	def post_config path, **payload
		refresh_token if Time.now >= @expire
		payload = JSON.generate payload
		headers = {
			'Authorization' => "Bearer #@id_token",
			'unity-player-id' => @user_id,
			'unity-installation-id' => installation_id,
			'Content-Type' => 'application/json',
		}
		res = Net::HTTP.post CONFIG_ENDPOINT + path, payload, headers
		res.value # raises error if not 200
		JSON.parse res.body, symbolize_names: true
	end

	def new_anonymous
		process_login post_player_auth 'authentication/anonymous'
	rescue Net::HTTPClientException => e
		raise "Failed to log in anonymous player (did you set the project ID correctly?): #{e.message}"
	end

	def refresh_token
		process_login post_player_auth 'authentication/session-token', sessionToken: @session_token
	rescue Net::HTTPClientException => e
		warn "Failed to refresh token: #{e.message}"
		new_anonymous
	end

	def process_login login
		@expire = Time.now + login[:expiresIn]
		@id_token = login[:idToken]
		@session_token = login[:sessionToken]
		@user = login[:user]
		@user_id = login[:userId]
		@env_id = get_env_id
		File.write @login_path, JSON.generate(login)
	end

	def get_env_id
		payload = @id_token.split('.')[1]
		claims = JSON.parse Base64.decode64 payload + '=' * ((4 - payload.length % 4) % 4)
		claims['aud'].find { _1.start_with? 'envId:' }&.delete_prefix 'envId:'
	end

	def installation_id
		return @installation_id if @installation_id
		if File.exist? @installation_id_path
			@installation_id = File.read @installation_id_path
		else
			@installation_id = SecureRandom.uuid
			File.write @installation_id_path, @installation_id
		end
		@installation_id
	end

	def settings
		post_config(
			'settings',
			projectId: @project_id,
			userId: installation_id,
			isDebugBuild: false,
			configType: 'settings',
			playerId: @user_id,
			analyticsUserId: installation_id,
			configAssignmentHash: nil,
			environmentId: @env_id,
			#packageVersion: REMOTE_CONFIG_PLUGIN_VERSION, # is this optional?
			originService: 'remote-config',
			attributes: {
				unity: { platform: 'Android' },
				app: {},
				user: {},
			},
		)[:configs][:settings]
	end

end
