# SIMPLE MASM CALCULATOR
## 📖 Project Description/Background
This code displays an ASCII art of a calculator on your screen, reads inputted numbers and mathematical operators, and displays the result.
This code was developed and tested in MASM on Visual Studio 2022 as part of my community college's assembly course. I decided to go overboard on an assignment and this was the result.
The calculator is very limited, as it can only handle one basic mathematical operation (addition, subtraction, multiplication), and can only take 7 digits for each operand. 

## 💾 How to Use
Load source assembly into Visual Studio 2022, configured to run 32-bit MASM with Irvine32. Run, and a calculator should appear on-screen. Alternatively, just run the binary executable file in the /bin directory.
Type in a number (with at most 7 digits, including negative symbol), an operator (+, -, *), and a second number. Then press 'E' (make sure the E is capitalized) on your keyboard to evaluate.
The calculator can also handle overflows from multiplication (32-bit signed integer used for storage) and syntax errors (including having more than one operator). 
If you want to clear the calculator screen, press 'C' (again, capitalized). If you want to exit the program, you can either press capital 'O' or you can just press the X on the window that pops up.

## 📝 Other Notes
The algorithm for calculating multiplication numbers is strange and inefficient (looped addition rather than a MUL instruction) because this was an assignment requirement, meant to show us that MUL can be accomplished with a fat bunch of ADDs. 

There are probably some random bugs that I couldn't hammer out - if you find one, let me know in my email address or the comments.
