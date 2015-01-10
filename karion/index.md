---
layout:page
title: Karion
---

# Karion Time 

This page gives you the current Karion date using your own time zone. The code for the Karion time service is still in beta tests and may cause problems. So do not use it as your serious service. You can always use [WolframAlpha](http://www.wolframalpha.com/input/?i=1996%2F01%2F08) for this matter

<br><br><br>
<center>
<b style="font-size:72px;">
<script>
var now = new Date();
var myBirth = new Date('01/08/1996');
var karion = daysBetween(myBirth, now);

var years = Math.floor( karion / 365 );
var months = Math.floor((karion - years * 365) / 30);
var days = Math.floor((karion - years * 365 - months * 30) - 5);

document.write(karion + "." + years + "." + months + "." + days);

function daysBetween(first, second) {

    var one = new Date(first.getFullYear(), first.getMonth(), first.getDate());
    var two = new Date(second.getFullYear(), second.getMonth(), second.getDate());

    // Do the math.
    var millisecondsPerDay = 1000 * 60 * 60 * 24;
    var millisBetween = two.getTime() - one.getTime();
    var days = millisBetween / millisecondsPerDay;

    // Round down.
    return Math.floor(days);
}
</script>
</b>
</center>

<br><br><br>
&copy; Copyright 2013-2015 Pouya Kary, All rights reserved. Karion is a date system for personal uses of Pouya Kary and any use of it, modification and derivative is of the date system is forbidden.