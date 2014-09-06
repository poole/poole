---
layout: page
title: Chess Knight Path Optimizer
---

Knight is one truly interesting member of the chess. Because of it's unique way of moving it's sometimes even hard to imagine how you should move it to a destination. One of this questions that some of the Chess teachers asks when they are teaching the Knight is: “How to move a Knight from bottom left of the board to the top right?” and you may simply find a solution in seconds but there is one question that you might never thought of and that's: “What is the minimum number of moves that you need to do this?” and once you get to the answer you may ask your self if there was a Chess not in the size of 8 how could I do this? This paper is an algorithm that I designed to generate the most optimized path for this task. The algorithm itself is just something useless that I made to fill my empty time but the way it is done is a good practice and technique that you may want to see. However when I was creating Arendelle I noticed that best language to make a graphical software for this algorithm is Arendelle, They are their best matches and so this paper explains why in some cases Arendelle will be your perfect choice
<br><br><br>

## Algorithm
The move of the horse is not symmetric thus we can not apply most of the algorithms we know that's why we need to study on the possible moves and then make something that use them as puzzle blocks. The perfect move to go from bottom left to the top right is of course one straight line but Knight does not move like this that's why we have to design paths that are as much as possible straight, It's like making mathematical recursion. We are not going to make a 100% straight lines but lines must be straight as possible. The most straight patterns are this two patterns here: <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/knight-photo1.png)

`M4` is exactly on the the diagonal but the problem is it's not an square's diagonal! However `M1` is really close to the diagonal that's why we have to use as much as possible. Let's have a look at the optimized path of the standard Chess: <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/knight-photo2.png)

As you see the optimized path for the standard board contains both `M1` and `M4` also there is one more move in our path called `M3` I have also created another move called `M5`: <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/m5andm4new.png)

Using this 4 moves we can actually generate optimized path for exactly all the board except 3x3 that has it's own move called `M2`. You may say how just using this 4 moves? That's one excellent question. Every 3 board we can add one more `M1` to the first of the path look at the examples below: <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/knight-photo4.png)

As you observe difference between the size of this two boards are 3 and as you see difference between this boards are one `M1` in their bottom left. It's possible to just calculate a board with a size dividable to 3 and two sizes after it like 6 , 7 and 8 then by adding `M1` to their first calculate all possible paths: <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/knight-photo5.png)

The path in size of 6 is made of `M4` + `M5`, the path in size of 7 if made of 2 `M1` and the path in size of 8 as discussed before is made `M1` + `M4` + `M3`. If you try to find paths in other sizes you will find this formulas ( As you know in programming % means remaining for example 4%3=1 , 5%3=2 and 6%3=0 ) <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/3formulas.png)

Remember that the last place of each move is the first place of the next move. Now let's see how this formula works on for example size of 21: <br>

![](https://raw.githubusercontent.com/pmkary/pmkary.github.io/master/Graphics/chessknight/knight-photo9.png) <br><br><br><br>

## Software
Designing a program to generate the path can make this even more fun and well the main reason of this paper is why you can and must use Arendelle to create a software for this program. All the pictures you see in this paper is created by a program written in Arendelle and attached to this. Arendelle is one language based on a grid of pixels and a pointer that you move and paint square pixels of the grid and Chess is a grid of squares that you move Knight in it so do you see the point? The language is natural for this task look at the source code in the following pages:<br><br>

**NOTE** : Following source code is a program written in Arendelle Language, to fully understand the code you have to be able to read Arendelle, If you have to background in Arendelle I suggest you take our introduction to Arendelle here: http://welcome.arendelle.org<br>
<br>

**NOTE** : The software has different ports and a runner that is available from [GitHub](http://github.com/pmkary/knight)<br><br> 

```
/* 
 * SPECIAL VERSION FOR WHITE TERMINAL 
 * SCREENS WITH RESPONSITIVE SPACINGS 
 * AND BORDERED BOARD AND BACKGROUND 
 * COLOR PATH MARKS. 
 */ 

// COPYRIGHT 2014 POUYA KARY 
// KARY KNIGHT PATH OPTIMIZER VERSION 1 
// FOR CALCULATING THE MINIMUM  MOVE 
// REQUIERD BY ONE CHESS KNIGHT TO MOVE 
// FROM BOTTOM LEFT OF A BOARD IN SIZE 
// OF N TO THE TOP RIGHT. 


   //////////////////////////////// 
   /// BUILDING THE CHESS BOARD /// 
   //////////////////////////////// 

// title 
   'Kary Knight\'s Path Optimizer' 

// How much is our board? ( @size X @size ) 
   ( size , "Please enter the size of your board:" ) 
 
// first spcaings 
   ( xspacings , ( #i - @size * 2 ) / 2 ) 
   ( yspacings , ( #j - @size     ) / 2 ) 
   [ @xspacings , r ]  [ @yspacings , d ] 

// The first color should not be the one 
// with capacity of 100% (Or #n of 0)
   n 

// creating the board 
   ( line  , 0 ) 
   [ @size , 
     i [ @xspacings , r ] [ @yspacings , d ] 
     [ @size , d ] [ @size , prpr nn ]  
     ( line , +1 ) 
     { @size % 2 = 0 , nn } 
   ] 

// Now we have to get to the bottom left 
// of our board. 
   i [ @xspacings , r ] 
   [ @yspacings + @size - 1  , d ] 
   { @size % 2 = 0 , nnn , n } 

// and because this software is designed for 
// white screen we do not color the path but 
// clear it!
   crc 


   ////////////////////////////// 
   /// RUNNING THE ALGORITHEM /// 
   ////////////////////////////// 

// Now we have to see what is the remaining 
// of the @size to 3 

   { @size % 3 = 0 , 
     // W0 /////////////////////////////////// 
        'Knight W0' 

     // M1 
        [ Floor( ( @size - 5 ) / 3 ) , 
            [ 2 , u ] [ 2 , rc ] 
          u [ 2 , r ] [ 2 , rc ] 
        ] 

     // M4 
        [ 2 , [ 2 , u ] [ 2 , rc ] ] 

     // M5 
        [ 3 , r ] d crc uu [ 2 , rc ]   

   , { @size % 3 = 1 , 
   // W1 /////////////////////////////////// 
      'Knight W1' 

   // M1 
      [ Floor( ( @size ) / 3 ) , 
          [ 2 , u ] [ 2 , rc ] 
        u [ 2 , r ] [ 2 , rc ] 
      ] 

   , 
   // W2 /////////////////////////////////// 
      'Knight W2' 

   // M1 
      [ Floor( ( @size - 5 ) / 3 ) , 
          [ 2 , u ] [ 2 , rc ] 
        u [ 2 , r ] [ 2 , rc ] 
      ] 

   // M4 
      [ 2 , [ 2 , u ] [ 2 , rc ] ] 
   
   // M3 
      [ 2 , d ] [ 2 , rc ] [ 2 , u ] [ 2 , rc ] 

   }} 
 
// Making the border 
  r  [ @size + 1     , prpdl ] 
  u  [ @size * 2     , lp    ] 
  ll [ @size + 1     , prpul ] 
  l  [ @size * 2 + 4 , rp    ] 

// done
```

<br><br>
## One final note
What I wanted to show you was this simple fact that every language is made for a task. Every language has it's own super powers. In other industries you see many people doing same tasks like there are millions of people who run their restaurant. We all know that most of them does the same, they all serve one food, they have one look and... but we need many because there is billions of people out there and one restaurant is not enough. But in our computing world you do not need many software with same tasks because if there be one all the people in the world can easily copy and use it but when there is more than one program you always know that each of them are made in different ways for different tasks. Use each language in their own right place.

