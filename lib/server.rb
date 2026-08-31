class Lyricast::Server < Sinatra::Base

	NEWS_KEYS = {
		announcement: /^Announcement\d+$/,
		weekly_mission: /^WeeklyMissionData\d+$/,
		month_ads_song: /^MonthAdsSong\d+$/,
	}

	NEWS_CLASSES = {
		announcement: Lyricast::Announcement,
		weekly_mission: Lyricast::WeeklyMission,
		month_ads_song: Lyricast::MonthAdsSong,
	}

	NEWS_TITLES = {
		announcement: :announcement,
		weekly_mission: :special_event,
		month_ads_song: :today_s_free_song,
	}

	set :api, Lyricast::RemoteSettings.new
	set :cache_mutex, Mutex.new
	set :settings_cache, nil
	set :cache_time, nil
	set :instance_id, Lyricast::Config::INSTANCE_ID
	set :cache_expire, Lyricast::Config::CACHE_SECONDS
	set :public_folder, File.join(Lyricast::Config::DATA_DIR, 'public')
	set :news_settings_cache, {}
	set :news_objects_cache, {}
	set :news_contents_cache, {}
	set :news_last_modified, {}

	helpers do
		def flush_cache_if_should
			now = Time.now
			return if settings.settings_cache && now - settings.cache_time < settings.cache_expire
			settings.cache_mutex.synchronize do
				settings.settings_cache = settings.api.settings
				settings.cache_time = now
				NEWS_KEYS.each do |key, regex|
					new_settings = settings.settings_cache.filter { |k, v| k =~ regex }
					next if new_settings == settings.news_settings_cache[key]
					settings.news_last_modified[key] = now
					settings.news_settings_cache[key] = new_settings
					settings.news_objects_cache[key] = nil
					Lyricast::Languages.each { settings.news_contents_cache[[key, _1]] = nil }
				end
			end
		end

		def news_contents key, lang
			flush_cache_if_should
			last_modified settings.news_last_modified[key]
			return settings.news_contents_cache[[key, lang]] if settings.news_contents_cache[[key, lang]]
			settings.news_objects_cache[key] ||= settings.news_settings_cache[key].values.map { NEWS_CLASSES[key].new _1 }
			result = settings.news_contents_cache[[key, lang]] = erb :atom, content_type: 'application/atom+xml', locals: {
				title: Lyricast::Languages.__send__(NEWS_TITLES[key], lang),
				key:,
				last_modified: settings.news_last_modified[key],
				instance_id: settings.instance_id,
				lang:,
				items: settings.news_objects_cache[key],
			}
			settings.news_objects_cache[key].each do |news|
				File.write File.join(settings.public_folder, news.static_path(lang)), news.full_html(lang)
			end
			result
		end
	end

	before do
		settings.api.log_in
		NEWS_CLASSES.each { FileUtils.mkdir_p File.join settings.public_folder, _2::STATIC_DIR }
	end

	NEWS_CLASSES.each do |key, klass|
		get "/#{klass::STATIC_DIR}.atom" do
			lang = params[:lang]
			lang = Lyricast::Languages.default if lang.nil? || lang.empty?
			lang = lang.to_sym
			lang = Lyricast::Languages.default unless Lyricast::Languages.include? lang
			news_contents key, lang
		end
	end
end
