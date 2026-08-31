module Lyricast::Languages
	LANGUAGES = %i[tw cn eng jp].freeze
	SHEET = Lyricast::Config.sheet :Language
	LIB, INDICES = SHEET.each_with_object [{}, []] do |item, (lib, indices)|
		unless item[:index].is_a? Integer
			indices.push []
			next
		end
		name = item[:eng].to_s.dup
		name.downcase!
		if name =~ /[\w\d]/
			name.gsub! /^[^\w\d]*|[^\w\d]*$/m, ''
			name.gsub! /[^\w\d]+/m, ?_
		end
		item = item.dup
		lib[name.to_sym] = indices.last[item[:index]] = item
		item[:group] = indices.last
	end.each &:freeze

	extend Enumerable
	def self.each(...)
		LANGUAGES.each(...)
	end

	LIB.each do |name, item|
		define_singleton_method name do |lang, offset: 0, sub: nil|
			raise "No such language: #{lang}" unless LANGUAGES.include? lang
			item[:group][item[:index] + offset][lang].to_s.dup.tap { _1.sub! ?*, sub if sub }
		end
	end

	def self.default
		LANGUAGES.first
	end

	def self.diff n, lang
		result = if n.to_i <= 10
			__send__ '1', lang, offset: n.to_i - 1
		else
			__send__ '11', lang, offset: n.to_i - 11
		end
		decimal = (n % 1 * 10).round
		result += __send__ ?+, lang if decimal > 5
		result += "(.#{decimal})"
		result
	end

	def self.special_diff n, lang
		k lang, offset: n.to_i - 15
	end

	def self.minimum_version lang
		{
			tw: '版本要求:',
			cn: '版本要求:',
			eng: 'Minimum Version:',
			jp: 'バージョン要件:',
		}[lang]
	end

	def self.jades lang
		{
			tw: '玉石',
			cn: '玉石',
			eng: 'Jades',
			jp: '玉石',
		}[lang]
	end

	def self.chart lang
		{
			tw: '樂譜',
			cn: '乐谱',
			eng: 'Chart',
			jp: '楽譜',
		}[lang]
	end

	def self.bcp47 lang
		{
			tw: 'zh-TW',
			cn: 'zh-CN',
			eng: 'en-US',
			jp: 'ja-JP',
		}[lang]
	end

	def self.include? lang
		LANGUAGES.include? lang
	end
end
