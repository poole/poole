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