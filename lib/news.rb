module Lyricast::News
	attr_reader :id, :date

	def title lang
		@title[lang]
	end

	def title_html lang
		escape_html title lang
	end

	def html_date date, lang
		date.strftime '<time datetime="%Y-%m-%d">%m/%d</time>'
	end

	def html_date_range lang
		"<p>#{html_date @date, lang} &tilde; #{html_date @date + (@length - 1), lang}</p>"
	end

	def text_date date, lang
		date.strftime '%m/%d'
	end

	def text_date_range lang
		"#{text_date @date, lang} ~ #{text_date @date + (@length - 1), lang}"
	end

	def escape_html text
		text.lines(chomp: true).map { CGI.escapeHTML _1 }.join '<br>'
	end

	def static_path lang
		"#{self.class::STATIC_DIR}/#{id}.#{lang}.html"
	end

	def feed_path lang
		"#{self.class::STATIC_DIR}.atom?lang=#{lang}"
	end

	def full_html lang
		title = escape_html title lang
		url = "#{Lyricast::Config::INSTANCE_ID}/#{static_path lang}"
		<<~HTML
			<!DOCTYPE html>
			<html lang="#{Lyricast::Languages.bcp47 lang}">
				<head>
					<title>#{title}</title>
					<meta charset="utf-8">
					<meta name="viewport" content="width=device-width, initial-scale=1.0">
					<meta name="generator" content="lyricast v#{Lyricast::VERSION}" />
					<meta property="og:title" content="#{title}" />
					<meta property="og:locale" content="#{Lyricast::Languages.bcp47 lang}" />
					<meta name="description" content="#{summary lang}" />
					<link rel="canonical" href="#{url}" />
					<meta property="og:site_name" content="Lyricast" />
					<meta property="og:type" content="website" />
					<link type="application/atom+xml" rel="alternate" href="#{Lyricast::Config::INSTANCE_ID}/#{feed_path lang}" />
				</head>
				<body>
					<h1>#{title_html lang}</h1>
					#{contents_html lang}
				</body>
			</html>
		HTML
	end
end

class Lyricast::Announcement
	include Lyricast::News
	STATIC_DIR = 'announcement'

	def initialize text
		@title = {}
		@contents = {}
		values = text.split ?\t
		@date = Date.new *values.shift.split(?/).map(&:to_i)
		@length = values.shift.to_i
		@id = values.shift.to_i
		Lyricast::Languages.each do |lang|
			@title[lang] = values.shift
			@contents[lang] = values.shift.tr ?|, ?\n
		end
	end

	def summary lang
		"#{text_date_range lang}\n#{@contents[lang]}"
	end

	def contents_html lang
		"#{html_date_range lang}\n<p>#{escape_html @contents[lang]}</p>"
	end
end

class Lyricast::MonthAdsSong
	include Lyricast::News
	STATIC_DIR = 'month-ads-song'

	def initialize text
		values = text.split ?\t
		@date = Date.new *values.shift.split(?/).map(&:to_i)
		@length = values.shift.to_i
		@id = values.shift.to_i
		%i[@monday_thursday @tuesday_friday @wednesday_saturday @sunday].each do |variable|
			instance_variable_set variable, values.shift.split(?,).map { Lyricast::Song.new _1.to_i }
		end
	end

	def title lang
		Lyricast::Languages.free_songs_of lang, sub: Lyricast::Languages.jan(lang, offset: @date.mon - 1)
	end

	def contents_html lang
		<<~HTML
			#{html_date_range lang}
			<table><tbody>
				<tr>
					<td>#{escape_html Lyricast::Languages.mon_thu lang}</td>
					<td>#{@monday_thursday.map { _1.html lang }.join '<br>'}</td>
				</tr>
				<tr>
					<td>#{escape_html Lyricast::Languages.tue_fri lang}</td>
					<td>#{@tuesday_friday.map { _1.html lang }.join '<br>'}</td>
				</tr>
				<tr>
					<td>#{escape_html Lyricast::Languages.wed_sat lang}</td>
					<td>#{@wednesday_saturday.map { _1.html lang }.join '<br>'}</td>
				</tr>
				<tr>
					<td>#{escape_html Lyricast::Languages.sun lang}</td>
					<td>#{@sunday.map { _1.html lang }.join '<br>'}</td>
				</tr>
			</tbody></table>
		HTML
	end

	def summary lang
		<<~TEXT
			#{text_date_range lang}

			#{Lyricast::Languages.mon_thu(lang).lines(chomp: true).join ' '}
			#{@monday_thursday.map { _1.summary lang }.join ?\n }

			#{Lyricast::Languages.tue_fri(lang).lines(chomp: true).join ' '}
			#{@tuesday_friday.map { _1.summary lang }.join ?\n }

			#{Lyricast::Languages.wed_sat(lang).lines(chomp: true).join ' '}
			#{@wednesday_saturday.map { _1.summary lang }.join ?\n }

			#{Lyricast::Languages.sun(lang).lines(chomp: true).join ' '}
			#{@sunday.map { _1.summary lang }.join ?\n }
		TEXT
	end
end

class Lyricast::WeeklyMission
	include Lyricast::News
	STATIC_DIR = 'weekly-mission'

	def initialize text
		lines = text.split(/\s*\|\s*/m).each &:strip!
		lines.delete_if { _1.start_with? ?# }
		values = lines.shift.split ?\t
		@id = values.shift.to_i
		@minimum_version = values.shift
		@length = values.shift.to_i
		@date = Date.new *values.shift.split(?/).map(&:to_i)
		@submissions = []
		while values = lines.shift&.split(?\t)
			case command = values.shift
			when ?T
				@submissions.push Submission.new values
			when ?M
				@submissions.last.stages.push Stage.new values, lines.shift
			else
				raise "Unknown command in weekly mission config: #{command}"
			end
		end
	end

	def title lang
		@submissions.first.title lang
	end

	def contents_html lang
		<<~HTML
			#{html_date_range lang}
			<p>#{Lyricast::Languages.minimum_version lang} #@minimum_version</p>
			#{@submissions.map { _1.html lang }.join ?\n}
		HTML
	end

	def summary lang
		<<~TEXT
			#{text_date_range lang}
			#{Lyricast::Languages.minimum_version lang} #@minimum_version

			#{@submissions.map { _1.summary lang }.join ?\n}
		TEXT
	end

	class Submission
		attr_reader :stages

		def initialize values
			@title = {}
			Lyricast::Languages.each { @title[_1] = values.shift }
			@stages = []
		end

		def title lang
			@title[lang]
		end

		def html lang
			<<~HTML
				<h2>#{CGI.escapeHTML title lang}</h2>
				<table>
					<thead><tr>
						<th scope="col">#{Lyricast::Languages.chart lang}</th>
						<th scope="col">#{Lyricast::Languages.target lang}</th>
						<th scope="col">#{Lyricast::Languages.bonus lang}</th>
					</tr></thead>
					<tbody>#{@stages.map { _1.html lang }.join}</tbody>
				</table>
			HTML
		end

		def summary lang
			"#{title lang}\n\n#{@stages.map { _1.summary lang }.join ?\n}"
		end
	end

	class Stage
		def initialize values, line
			@title = {}
			Lyricast::Languages.each { @title[_1] = values.shift }
			values = line.split ?\t
			@mode = values.shift.to_i
			@diff = values.shift.to_i
			@song = Lyricast::Song.new values.shift.to_i
			@target = Target.new values.shift.to_i, values.shift.to_i
			@reward = Reward.new values.shift.to_i, values.shift.to_i
		end

		def html lang
			"<tr><td>#{@song.html lang, @diff}</td><td>#{@target.html lang}</td><td>#{@reward.html lang}</td></tr>"
		end

		def summary lang
			<<~TEXT
				#{@song.summary lang, @diff}
				#{Lyricast::Languages.target lang} #{@target.summary lang}
				#{Lyricast::Languages.bonus lang} #{@reward.summary lang}
			TEXT
		end
	end

	class Target
		AUTO_VALUES = {
			rank: [2, 3, 4, 5, 6, 6],
			score: [600000, 700000, 800000, 900000, 960000, 1000000],
			combo: [20, 35, 50, 60, 80, 100],
			perfect_ratio: [40, 60, 75, 85, 95, 100],
			miss_count: [30, 20, 15, 8, 1, 0],
		}

		def initialize type, value
			@type = %i[none rank score combo perfect_ratio miss_count][type] || :random
			@value = value.negative? && @type != :random ? AUTO_VALUES[@type][-value - 1] : value
		end

		def summary lang
			result = ""
			case @type
			when :rank
				result += Lyricast::Languages.rank lang
				result += ' '
				result += @value == 7 ? Lyricast::Languages.s_all_perfect(lang) : Lyricast::Languages.e(lang, offset: -@value + 1)
				result += Lyricast::Languages.__send__ ' ', lang
			when :score
				result += Lyricast::Languages.more_than lang
				result += ' '
				result += Lyricast::Languages.score lang
				result += ' '
				result += @value.to_s
				result += Lyricast::Languages.__send__ ' ', lang
			when :combo
				result += Lyricast::Languages.more_than lang
				result += ' '
				result += Lyricast::Languages.combo lang
				result += ' '
				result += @value.to_s + ?%
				result += Lyricast::Languages.__send__ ' ', lang
			when :perfect_ratio
				result += Lyricast::Languages.more_than lang
				result += ' '
				result += Lyricast::Languages.perfect lang
				result += ' '
				result += @value.to_s + ?%
				result += Lyricast::Languages.__send__ ' ', lang
			when :miss_count
				result += Lyricast::Languages.miss lang
				result += ' '
				result += Lyricast::Languages.less_than lang if lang == :eng
				result += ' ' if lang == :eng
				result += @value.to_s
				result += Lyricast::Languages.less_than lang if lang != :eng
			else
				result += ?-
			end
			result.strip
		end

		def html lang
			CGI.escapeHTML summary lang
		end
	end

	class Reward
		def initialize type, value
			@type = %i[coin head song gem head head role][type] || :none
			@value = case @type
			when :head
				Lyricast::Head.new value
			when :role
				Lyricast::Role.new value
			when :song
				Lyricast::Song.new value
			else
				value
			end
		end

		def summary lang
			case @type
			when :gem
				"#@value #{Lyricast::Languages.jades lang}"
			when :coin
				"#@value #{Lyricast::Languages.coins lang}"
			when :head, :role, :song
				@value.summary lang
			end
		end

		def html lang
			case @type
			when :gem
				"#@value #{Lyricast::Languages.jades lang}"
			when :coin
				"#@value #{Lyricast::Languages.coins lang}"
			when :head, :role, :song
				@value.html lang
			end
		end
	end
end
