def getFizzBuzz(n)
	words = [("fizz" if n % 3 == 0), ("buzz" if n % 5 == 0)].compact;
end

(1..100).each{|n|
	words = getFizzBuzz(n)
	puts (words.empty? ? n : words.join)
}
