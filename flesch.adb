-- Flesch index rules can be found here: http://www.csc.villanova.edu/~mdamian/Past/csc3990fa08/papers/nlp/talburt_1986.pdf

with ada.text_io; use ada.text_io;
with ada.integer_text_io; use ada.integer_text_io;
with ada.float_text_io; use ada.float_text_io;
with ada.io_exceptions; use ada.io_exceptions;
with ada.strings.unbounded; use ada.strings.unbounded;
with ada.strings.unbounded.text_io; use ada.strings.unbounded.text_io;

procedure flesch is 
	-- declaration of variables
	type str is array(1..1000) of unbounded_string;
	fileName : unbounded_string;
	anArr : str;	
	infp : file_type;
	length : integer;
	strLen : integer;
	wordCount : integer;
	senCount : integer;
	sylCount : integer;
	temp : integer;
	buffer : string(1..16);
	curr : integer;
	grade : float;
	index : float;
	aveTwo : float;
	aveOne : float;
	
	-- function to get the readability of the passage based on the index
	-- parameter is the index
	-- returns a string indicating the readability
	function getIndex(index : in integer) return string is
		result : string(1..16);
	begin
		if index < 30 then
			result := "Very Difficult  ";
		elsif index > 29 and index < 50 then
			result := "Difficult       ";
		elsif index > 49 and index < 60 then
			result := "Fairly Difficult";
		elsif index > 59 and index < 70 then
			result := "Plain English   ";
		elsif index > 69 and index < 80 then
			result := "Fairly Easy     ";
		elsif index > 79 and index < 90 then
			result := "Easy            ";
		elsif index > 90 then
			result := "Very Easy       ";
		end if;
		return result;
	end getIndex;
	
	-- function to calculate the flesch-kincaid grade level
	-- parameters are the word, sentence and syllable count
	-- returns a float indicating the flesch-kincaid grade value based on the equation
	function FleschKincaid(words : in integer; syllabs : in integer; sentences : in integer) return float is
		value : float;
		first : float;
		second : float;
	begin
		first := float(words) / float(sentences);
		first := first * 0.39;
		second := float(syllabs) / float(words);
		second := second * 11.8;
		value := first + second - 15.59;
		return value;
	end FleschKincaid;
	
	-- function to calculate the flesch index level
	-- parameters are the word, sentence and syllable count
	-- returns a float indicating the flesch index value based on the equation
	function FleschIndex(words2 : in integer; syllabs2 : in integer; sentences2 : in integer) return float is
		value2 : float;
		first2 : float;
		second2 : float;
	begin
		first2 := float(words2) / float(sentences2);
		first2 := first2 * 1.015;
		second2 := float(syllabs2) / float(words2);
		second2 := second2 * 84.6;
		value2 := 206.835 - (first2 + second2);	
		return value2;
	end FleschIndex;
	
	-- function to read in the file and assign every line to an array index
	-- parameter one : length of the filename (integer)
	-- parameter two: file name inputted by the user in the main program (unbounded string)
	-- returns an array of unbounded strings, each index containing a line from the file
	function readFile(len : in integer; fileName : in unbounded_string) return str is 
        s : unbounded_string;
        a : str;
        j : integer;
        newFile : string(1..len);
    begin
		newFile := to_string(fileName);
        open(infp,in_file,newFile);
        j := 1;
		loop
		-- only read the file until the end
		exit when end_of_file(infp);
            get_line(infp,s);
            -- assign each line to an array index
            a(j) := s;
            j := j+1;
        end loop;
        close(infp);
		return a;
    end readFile;
    
    -- function to check if a single character is a punctuation point
    -- parameter is the single character to check
    -- returns 1 if it is a punction point, 0 if not
    -- punction points for the flesch index calculator are definied in the flesch index rules (see header)
    function isPunct(c : in character) return integer is
		count : integer;
    begin
		count := 0;
		if c = '.' then
			count := 1;
		elsif c = '!' then
			count := 1;
		elsif c = '?' then
			count := 1;
		elsif c = ':' then
			count := 1;
		elsif c = ';' then
			count := 1;
		end if;
		return count;
	end isPunct;
	
	-- function to check if a single character is a vowel
    -- parameter is the single character to check
    -- returns 1 if it is a vowel, 0 if not
    -- vowels for the flesch index calculator are definied in the flesch index rules (see header)
	function isVowel(m : character) return integer is
		flag : integer;
	begin
		flag := 0;
		if m = 'a' or m = 'A' then
			flag := 1;
		elsif m = 'e' or m = 'E' then
			flag := 1;
		elsif m = 'i' or m = 'I' then
			flag := 1;
		elsif m = 'o' or m = 'O' then
			flag := 1;
		elsif m = 'u' or m = 'U' then
			flag := 1;
		elsif m = 'y' or m = 'Y' then
			flag := 1;
		end if;
		return flag;
	end isVowel;
	
	-- function to get the number of syllables in a string
	-- parameter one: the string to check (unbounded string)
	-- parameter two: the number of words in that string (integer)
	-- parameter three: the number of characters in that string (integer);
	-- returns an integer indicating the number of syllables in the string
	-- syllable combinations are defined in the flesch index rules (see header)
	function getSyls(line : in unbounded_string; numWords : in integer; strLen : in integer) return integer is 
		num : integer;
		-- delcare an integer array to count the number of syllables for each word in the string
		-- each index in the array symbolizes a single word in the string
		type ints is array(1..1000) of integer;
		sylArr : ints;
		totalSyls : integer;
	begin
		num := 1;
		totalSyls := 0;
		-- assign each index in the integer array to 0
		for p in 1..1000 loop
			sylArr(p) := 0;
		end loop;
		for i in 1..strLen loop
			if i /= 1 then
				-- increment the integer array index counter as you find new words
				if element(line,i) /= ' ' and element(line,i-1) = ' ' then
					num := num + 1;
				end if;
			end if;
			if i /= 1 then
				-- if the current character is a vowel and the previous one is not, then increment the syllable counter
				-- this will take into account single vowels or groups of vowels (which will only be counted once)
				if isVowel(element(line,i)) = 1 and isVowel(element(line, i-1)) /= 1 then
					sylArr(num) := sylArr(num) + 1;
				end if;
				if element(line,i) = ' ' or isPunct(element(line,i)) = 1 or element(line,i) = ',' then
					-- decrement counter for "e" at the end of a word but not "le"
					if element(line, i-1) = 'e' or element(line, i-1) = 'E' then
						if i > 2 then 
							if element(line, i-2) /= 'l' or element(line, i-2) /= 'L' then
								sylArr(num) := sylArr(num) - 1;
							end if;
						else
							sylArr(num) := sylArr(num) - 1;
						end if;
					end if;
					if i > 2 then
						-- decrement counter for "es" or "ed" at the end of a word
						if element(line, i-1) = 's' or element(line, i-1) = 'S' then
							if element(line, i-2) = 'e' or element(line, i-2) = 'E' then
								sylArr(num) := sylArr(num) -1;
							end if;
						elsif element(line, i-1) = 'd' or element(line, i-1) = 'D' then 
							if element(line,i-2) = 'e' or element(line,i-2) = 'E' then
								sylArr(num) := sylArr(num)-1;
							end if;
						end if;
					end if;
				end if;
			elsif i = 1 then
				-- if the first letter is a single vowel then increment the counter
				if isVowel(element(line, i)) = 1 then
					sylArr(num) := sylArr(num) + 1;
				end if;
			end if;
		end loop;
		-- if there was a word that didn't get counted to have a syllable then set it to one
		for k in 1..numWords loop
			if sylArr(k) = 0 then
				sylArr(k) := 1;
			end if;
		end loop;
		-- add up all the syllables in the array
		for l in 1..numWords loop
			totalSyls := totalSyls + sylArr(l);
		end loop;
		return totalSyls;
	end getSyls;
		
-- main procedure starts here
begin
	wordCount := 0;
	senCount := 0;
	length := 0;
	sylCount := 0;
	-- get file name from the user
	new_line;
	put("Please input a valid file name containing a passage: ");
	get_line(fileName);
	length := ada.strings.unbounded.length(fileName);
	-- call readFile function to assign array of lines in file
	anArr := readFile(length, fileName);
	for i in 1..1000 loop
		strLen := ada.strings.unbounded.length(anArr(i));
		temp := 0;
		for k in 1..strLen loop
			-- count the number of words in each line by looking at number of space and non space combinations
			if k = 1 then
				wordCount := wordCount + 1;
				temp := temp + 1;
			elsif k /= 1 then
				if element(anArr(i),k) /= ' ' and isPunct(element(anArr(i),k)) /= 1 and element(anArr(i), k-1) = ' ' then
					wordCount := wordCount + 1;
					temp := temp + 1;
				end if;	
			end if;
			-- count the number of sentences in each line by looking at the number of punctuation points
			if isPunct(element(anArr(i),k)) = 1 then
				senCount := senCount + 1;
			end if;
		end loop;
		if strLen /= 0 then
			-- call function to count number of syllables for each line
			curr := getSyls(anArr(i), temp, strLen);
			sylCount := sylCount + curr;
		end if;
	end loop;
	-- print out values to the user
	new_line;
	put("Number of Sentences ");
	put(senCount);
	new_line;
	put("Number of Words ");
	put(wordCount);
	new_line;
	put("Number of Syllables ");
	put(sylCount);
	new_line;
	put("Average Sentence Length ");
	aveOne := float(wordCount) / float(senCount);
	put(aveOne, Fore => 10, Aft => 2, Exp => 0);
	new_line;
	put("Average Syllables Per Word ");
	aveTwo := float(sylCount) / float(wordCount);
	put(aveTwo, Fore => 10, Aft => 2, Exp => 0);
	new_line;
	put("Flesch Index ");
	index := FleschIndex(wordCount, sylCount, senCount);
	put(index, Fore => 10, Aft => 2, Exp => 0);
	buffer := getIndex(integer(index));
	new_line;
	put("Grade Level Equivalent");
	grade := FleschKincaid(wordCount, sylCount, senCount);
	put(grade, Fore => 10, Aft => 2, Exp => 0);
	new_line;
	new_line;
	put("This passage is classified as ");
	put(buffer);
	new_line;
	new_line;
end flesch;
