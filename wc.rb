# frozen_string_literal: true

require 'optparse'

class WC
  def initialize
    # オプションの指定によって各フラグをtrueにする
    OptionParser.new do |op|
      op.on('-l') { |b| @lines_flg = true }
      op.on('-w') { |b| @words_flg = true }
      op.on('-c') { |b| @bytes_flg = true }
      @no_opt_flg = true if ARGV.length == op.parse!(ARGV).length
    end

    @files = ARGV
    # ファイルの指定が無い場合には標準入力で受け取る
    @inputs = []
    if @files.empty?
      while (line = gets)
        @inputs.push(line)
      end
    end

    # 複数ファイル時の各合計用のインスタンス変数
    @total_lines = 0
    @total_words = 0
    @total_bytes = 0
  end

  # ファイルを行ごとに読み込み配列で返す
  # @param [String, NilClass] file
  # @return [Array]
  def get_lines(file)
    lines = []

    unless file.nil?
      File.foreach(file) do |line|
        lines.push(line)
      end
      return lines
    end
    # ファイルの指定がない場合は標準入力の配列を返す
    @inputs
  end

  # 行数を数えて返す
  # @param [String, NilClass] file
  # @return [Integer]
  def get_lines_count(file)
    lines_sum = 0
    lines = get_lines(file)

    # wcコマンドに合わせるために、最終行の文末に改行コードが無かった場合には行数を-1する
    lines_sum += if lines.last =~ /\R$/
                   lines.size
                 else
                   lines.size - 1
                 end
    # 行数のtotalに加算
    @total_lines += lines_sum
    lines_sum
  end

  # 単語数を数えて返す
  # @param [String, NilClass] file
  # @return [Integer]
  def get_words_count(file)
    words_sum = 0
    lines = get_lines(file)

    # 正規表現に合うものの個数を数える
    lines.each do |l|
      words = l.scan(/[\w-]+/)
      words_sum += words.length
    end
    # 単語数のtotalに加算
    @total_words += words_sum
    words_sum
  end

  # バイト数を数えて返す
  # @param [String, NilClass] file
  # @return [Integer]
  def get_bytes(file)
    lines = get_lines(file)
    bytes_sum = 0

    # バイト数の合計を調べる
    lines.each do |l|
      bytes_sum += l.bytesize
    end
    # バイト数のtotalに加算
    @total_bytes += bytes_sum
    bytes_sum
  end

  # 出力時の空白数を返す
  # @param [String] cnt
  # @return [String]
  def get_blank(cnt)
    # wcコマンドに合わせた空白数に調整する
    if (8 - cnt.length).positive?
      ' ' * (8 - cnt.length)
    else
      ' '
    end
  end

  # 行数と空白を返す
  # @param [String, NilClass] file
  # @return [[String, String]]
  def get_lc_cnt_and_blank(file)
    l_cnt = get_lines_count(file).to_s
    [l_cnt, get_blank(l_cnt)]
  end

  # 単語数と空白を返す
  # @param [String, NilClass] file
  # @return [[String, String]]
  def get_wc_cnt_and_blank(file)
    w_cnt = get_words_count(file).to_s
    [w_cnt, get_blank(w_cnt)]
  end

  # バイト数と空白を返す
  # @param [String, NilClass] file
  # @return [[String, String]]
  def get_b_cnt_and_blank(file)
    bytes = get_bytes(file).to_s
    [bytes, get_blank(bytes)]
  end

  # 結果を出力する
  # @param [String, NilClass] lc_blank
  # @param [String, Integer, NilClass] l_cnt
  # @param [String, NilClass] wc_blank
  # @param [String, Integer, NilClass] w_cnt
  # @param [String, NilClass] b_blank
  # @param [String, Integer, NilClass] bytes
  # @param [String, NilClass] file
  def print(lc_blank, l_cnt, wc_blank, w_cnt, b_blank, bytes, file)
    puts "#{lc_blank}#{l_cnt}#{wc_blank}#{w_cnt}#{b_blank}#{bytes} #{file}"
  end

  # オプションに合わせて、各結果を出力する
  # @param [String, NilClass] file
  def check_options_and_print(file)
    # オプションの指定があった場合
    l_cnt, lc_blank = get_lc_cnt_and_blank(file) if @lines_flg
    w_cnt, wc_blank = get_wc_cnt_and_blank(file) if @words_flg
    bytes, b_blank = get_b_cnt_and_blank(file) if @bytes_flg

    # オプションの指定が無かった場合
    if @no_opt_flg
      l_cnt, lc_blank = get_lc_cnt_and_blank(file)
      w_cnt, wc_blank = get_wc_cnt_and_blank(file)
      bytes, b_blank = get_b_cnt_and_blank(file)
    end

    # 出力する
    print(lc_blank, l_cnt, wc_blank, w_cnt, b_blank, bytes, file)
  end

  # 0をnilに変換する
  # @param [Integer] num
  # @return [Integer, NilClass]
  def zero_to_nil(num)
    return nil if num.zero?

    num
  end

  # totalを出力する
  def print_total
    # オプションの指定があった場合
    lc_blank = get_blank(@total_lines.to_s) if @lines_flg
    wc_blank = get_blank(@total_words.to_s) if @words_flg
    b_blank = get_blank(@total_bytes.to_s) if @bytes_flg

    # オプションの指定が無かった場合
    if @no_opt_flg
      lc_blank = get_blank(@total_lines.to_s)
      wc_blank = get_blank(@total_words.to_s)
      b_blank = get_blank(@total_bytes.to_s)
    end
    print(lc_blank, zero_to_nil(@total_lines), wc_blank, zero_to_nil(@total_words), b_blank, zero_to_nil(@total_bytes), 'total')
  end

  # wcを実行する
  def run
    # ファイルごとに実行し、出力する
    @files.each do |file|
      check_options_and_print(file)
    end
    # 標準入力の場合はここで出力する
    check_options_and_print(nil) if @files.empty?

    # 複数ファイルが指定された場合にはtotalを出力する
    print_total if @files.size > 1
  end
end

def main
  wc = WC.new
  wc.run
end

main
