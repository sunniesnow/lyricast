class Lyricast::Song

	SHEET = Lyricast::Config.sheet :SongLib
	LIB = SHEET.each_with_object [] do |item, lib|
		next unless item[:index].is_a? Integer
		lib[item[:index]] = item
	end.freeze
	DIFF_KEYS = Hash[(1..5).zip %i[easy normal hard master special]].freeze
	DIFF_COLORS = {
		easy: '#3eb9fd',
		normal: '#f19e56',
		hard: '#e75e74',
		master: '#8c68f3',
		special: '#f156ee'
	}.freeze

	def initialize id
		@id = id
		item = LIB[@id]
		@title = Lyricast::Languages.each_with_object({}) do |lang, map|
			map[lang] = lang == Lyricast::Languages.default ? item[:songname] : item[:"songname#{lang}"]
		end
		@diffs = DIFF_KEYS.each_with_object({}) do |(_, key), map|
			diff = item[:"diff#{key[/^.[^aeiou]*/]}"]
			map[key] = diff if diff >= 0
		end
	end

	def diff diff_key, lang
		if diff_key == :special && @diffs[:special] >= 15
			Lyricast::Languages.special_diff @diffs[:special], lang
		else
			Lyricast::Languages.diff @diffs[diff_key], lang
		end
	end

	def with_color text, color
		%{<span style="color: #{color};">#{CGI.escapeHTML text}</span>}
	end

	def html lang, diff_key = nil
		diff_key = DIFF_KEYS[diff_key] if diff_key.is_a? Integer
		result = CGI.escapeHTML @title[lang]
		result += ' '
		if diff_key.nil?
			result += @diffs.keys.map { with_color diff(_1, lang), DIFF_COLORS[_1] }.join ' / '
		else
			result += with_color "#{Lyricast::Languages.__send__ diff_key, lang} #{diff diff_key, lang}", DIFF_COLORS[diff_key]
		end
	end

	def summary lang, diff_key = nil
		diff_key = DIFF_KEYS[diff_key] if diff_key.is_a? Integer
		result = @title[lang] + ' '
		if diff_key.nil?
			result += @diffs.keys.map { diff _1, lang }.join ' / '
		else
			result += "#{Lyricast::Languages.__send__ diff_key, lang} #{diff diff_key, lang}"
		end
	end
end

class Lyricast::Head

	SHEET = Lyricast::Config.sheet :HeadData
	LIB = SHEET.each_with_object [] do |item, lib|
		next unless item[:index].is_a? Integer
		lib[item[:index]] = item
	end.freeze

	def initialize id
		@id = id
		item = LIB[@id]
		@stamp = { tw: item[:stamp], cn: item[:stampcn] }
		Lyricast::Languages.each do |lang|
			@stamp[lang] = item[:stamp] unless @stamp[lang]
		end
		@award_type = %i[none fx song head role][item[:awardtype]] || :none
		@award_value = item[:awardvalue]
		@award = {
			tw: item[:awardinfocht],
			cn: item[:awardinfocn],
			eng: item[:awardinfoen],
			jp: item[:awardinfojp],
		}
		@award.transform_values! { _1&.sub ?*, @award_value.to_s }
		@max = item[:max]
	end

	def html lang
		CGI.escapeHTML summary lang
	end

	def summary lang
		result = "#{Lyricast::Languages.avatar_no lang} #@id (#{@stamp[lang]})"
		result += " (#{Lyricast::Languages.collect_to_get_reward lang, sub: @max.to_s} #{@award[lang]})" if @award_type != :none
		result
	end
end

class Lyricast::Role
	SHEET = Lyricast::Config.sheet :RoleName
	LIB = SHEET.each_with_object [] do |item, lib|
		next unless item[:index].is_a? Integer
		lib[item[:index]] = item
	end.freeze

	def initialize id
		@id = id
		item = LIB[id]
		@name = item.slice *Lyricast::Languages
	end

	def summary lang
		"#{Lyricast::Languages.theme_unlock lang} #{@name[lang]}"
	end

	def html lang
		CGI.escapeHTML summary lang
	end
end
