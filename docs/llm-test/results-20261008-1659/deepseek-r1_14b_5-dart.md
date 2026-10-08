# deepseek-r1:14b — 5-dart

## Prompt
Write a Flutter/Dart function that takes a list of medication times (as "HH:mm" strings) and returns the next time after a given "now" time, wrapping to the next day if needed. Include a short test. Keep it under 60 lines.

## Thinking
Okay, I need to write a Flutter/Dart function that takes a list of medication times in "HH:mm" format and returns the next time after a given "now" time, possibly wrapping to the next day. The user also wants a short test and the code should be under 60 lines.

First, I should think about how to parse the "HH:mm" strings into a time that can be compared. Maybe using DateTime or TimeOfDay would be helpful. But since I need to compare times, perhaps converting them into total minutes since midnight would make it easier.

So, I'll create a helper function, maybe called parseTime, that takes a String and returns the total minutes. That function would split the string into hours and minutes, convert each to integers, and calculate total minutes as hours * 60 + minutes.

Next, the main function, getNextMedTime, takes a List of Strings (medicationTimes) and a String (currentTime). I'll need to process each time in the list, parse them into minutes, and also parse the current time into minutes.

The goal is to find the earliest medication time that is later than the current time. If all times are earlier, then the next day's times should be considered.

So, for each parsed time, I'll check if it's greater than the current minutes. If none are, I'll wrap around to the next day and consider the earliest time as the next one.

Wait, but how do I handle wrapping? Maybe for each time, if it's less than or equal to current, add 24*60 to it to represent the next day. Then, find the minimum of these adjusted times. Then, convert that back into a time string.

Wait, but maybe a better approach is to compute the difference between each time and current time. If the difference is positive, it's a candidate. If all are negative, then the next day's times are the candidates.

Alternatively, for each time in the list, calculate the time until the next occurrence. If the time is in the past, add 24 hours to it. Then, find the minimum of these times.

Wait, perhaps for each time, compute the difference in minutes. If the time is <= current, then the difference would be (time + 24*60 - current). Otherwise, it's (time - current). The smallest positive difference would be the next time.

Wait, no. Because if a time is in the future, its difference is positive. If it's in the past, we add 24*60 to it to make it the next day's time.

So, for each time, calculate:

if time > now: difference is time - now
else: difference is (time + 24*60) - now

Then, among all these differences, find the minimum positive one, and the corresponding time.

Wait, but the minimum difference would give the next occurrence. So, the function can compute all the possible next times, considering wrapping, and pick the earliest one.

So, steps:

1. Parse all medication times into minutes.
2. Parse current time into minutes.
3. For each medTime:
   a. if medTime > currentTime: candidate is medTime
   b. else: candidate is medTime + 24*60
4. Find the minimum candidate.
5. If the minimum candidate is from the next day, then the time is candidate - 24*60, else it's the same day.
Wait, no. Because the candidate is either the same day or next day. So, to get the display time, if the candidate is more than 24*60, subtract 24*60 to get the time on the next day.

Wait, no. Because when we added 24*60 to a past time, the candidate is the next day's time. So, when we find the minimum candidate, which could be either same day or next day, we can then format it as HH:mm, considering whether it's on the same day or next.

But perhaps a better approach is to compute the actual next occurrence time as a DateTime, then format it back.

Alternatively, perhaps using DateTime objects would be easier. Let me think.

But perhaps it's easier to work with minutes for comparison.

So, let's outline the code.

First, the helper function:

int parseTime(String time) {
   split into hours and minutes, convert to ints, return hours*60 + minutes.
}

Then, in the main function:

List<int> times = medicationTimes.map(parseTime).toList();
int now = parseTime(currentTime);

List<int> nextCandidates = times.map((t) {
   if (t > now) return t;
   else return t + 24*60;
}).toList();

int nextTime = nextCandidates.reduce(min);

But wait, the reduce min will give the smallest candidate. Then, we need to see if this nextTime is on the same day or next day.

Wait, no. Because nextTime could be either same day or next day. So, to get the display time, if nextTime >= 24*60, then subtract 24*60 to get the time on the next day.

Wait, no. Because if nextTime is, say, 720 (12:00), which is 12pm, and now is 1440 (24*60=1440?), wait no, 24*60 is 1440, but 23:59 is 1439. So, if current time is, say, 1439 (23:59), and a med time is 0 (00:00), then 0 + 1440 = 1440, which is 0 again but next day.

Wait, perhaps the helper function should return the total minutes since midnight, so 0-1439.

So, in the candidate calculation, if t <= now, then add 1440 to get the next day's time.

So, for example:

t is 0, now is 1439: t <= now, so candidate is 0 + 1440 = 1440.

t is 100, now is 50: candidate is 100.

Then, nextTime would be the minimum of all candidates.

Once nextTime is found, to get the display time:

if nextTime >= 1440: then subtract 1440, and it's the next day's time.

Wait, no. Because nextTime could be 1440, which is 0 of the next day.

So, in code:

int minutesSinceMidnight = nextTime % 1440;
int hours = (minutesSinceMidnight / 60).floor();
int minutes = minutesSinceMidnight % 60;

Then, format as "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}".

Wait, but if nextTime is 1440, then 1440 % 1440 is 0, which is correct.

So, the function would return the correct time, whether it's same day or next day.

Now, putting it all together.

But wait, what about the case where multiple times are in the future? We need the earliest one.

Yes, because nextCandidates contains all possible next occurrences, and reduce(min) will pick the earliest.

What about when all times are in the past? Then all candidates are t + 1440, so the earliest would be the smallest t + 1440, which is the earliest time on the next day.

Now, let's think about the test case.

Sample test:

medicationTimes = ["08:00", "12:00", "16:00"]
now = "23:30"

Parsed times: 480, 720, 960.

Now is 23*60 +30 = 1410.

For each medTime:

480 < 1410: candidate is 480 + 1440 = 1920.

720 < 1410: 720 + 1440 = 2160.

960 < 1410: 960 + 1440 = 2400.

So nextCandidates are [1920, 2160, 2400]. The min is 1920.

1920 % 1440 = 480, which is 08:00. So the next time is 08:00 next day.

Another test case:

medicationTimes = ["23:00"]
now = "23:30"

Parsed times: 23*60=1380.

Now is 23*60 +30=1410.

1380 <1410: candidate is 1380+1440=2820.

nextTime is 2820.

2820 %1440= 2820-2*1440=2820-2880= -60? Wait, no. Wait, 2820 /1440 is 1 with remainder 980.

Wait, 1440 *1=1440, 2820-1440=1380.

So 1380 is 23:00, which is next day.

So function returns "23:00".

Another test case:

medicationTimes = ["00:00", "12:00"]
now = "13:00"

Parsed times: 0, 720.

Now is 780.

0 <780: candidate 0+1440=1440.

720 <780: candidate 720+1440=2160.

So nextCandidates are 1440, 2160. Min is 1440.

1440 %1440=0 → "00:00".

So function returns "00:00" next day.

Another test case:

medicationTimes = ["14:00", "02:00"]
now = "13:00"

Parsed times: 840, 120.

Now is 780.

840>780: candidate 840.

120 <780: candidate 120+1440=1560.

So nextCandidates are 840, 1560. Min is 840 → 14:00 same day.

So function returns "14:00".

So the logic seems to handle these cases.

Now, writing the code.

First, the helper function:

int parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
}

Then, the main function:

String getNextMedTime(List<String> times, String now) {
    final parsedTimes = times.map(parseTime).toList();
    final nowTime = parseTime(now);
    final nextCandidates = parsedTimes.map((t) {
        return t > nowTime ? t : t + 1440;
    }).toList();
    final nextTime = nextCandidates.reduce((a, b) => a < b ? a : b);
    final minutes = nextTime % 1440;
    final hours = (minutes / 60).floor();
    final mins = minutes % 60;
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
}

Wait, but in Dart, the reduce function for a list with min is the same as taking the minimum. So, nextCandidates.reduce((a,b)=>a< b ?a :b) is correct.

Then, to format the time with leading zeros.

Now, the test.

void main() {
    // Test 1
    final times = ["08:00", "12:00", "16:00"];
    final now = "23:30";
    expect(getNextMedTime(times, now), "08:00");

    // Test 2
    final times2 = ["23:00"];
    final now2 = "23:30";
    expect(getNextMedTime(times2, now2), "23:00");

    // Test 3
    final times3 = ["00:00", "12:00"];
    final now3 = "13:00";
    expect(getNextMedTime(times3, now3), "00:00");

    // Test 4
    final times4 = ["14:00", "02:00"];
    final now4 = "13:00";
    expect(getNextMedTime(times4, now4), "14:00");
}

Wait, but in Dart, to run tests, I need to import 'dart:core' and use testing framework. But since the user wants a short test, perhaps just showing the test cases is enough.

Wait, but the code is in the function, so perhaps the main function can have these tests.

But the user said to include a short test, so perhaps just a few examples.

Now, counting lines.

The helper function is 4 lines.

The main function is 8 lines.

The test is 10 lines.

But total lines would be 22, which is under 60.

But wait, the code I wrote earlier is:

int parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
}

String getNextMedTime(List<String> times, String now) {
    final parsedTimes = times.map(parseTime).toList();
    final nowTime = parseTime(now);
    final nextCandidates = parsedTimes.map((t) {
        return t > nowTime ? t : t + 1440;
    }).toList();
    final nextTime = nextCandidates.reduce((a, b) => a < b ? a : b);
    final minutes = nextTime % 1440;
    final hours = (minutes / 60).floor();
    final mins = minutes % 60;
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
}

void main() {
    // Test cases
    print(getNextMedTime(["08:00", "12:00", "16:00"], "23:30")); // "08:00"
    print(getNextMedTime(["23:00"], "23:30")); // "23:00"
    print(getNextMedTime(["00:00", "12:00"], "13:00")); // "00:00"
    print(getNextMedTime(["14:00", "02:00"], "13:00")); // "14:00"
}

This is about 20 lines, under 60.

I think this should work.


## Answer
Here's a concise Flutter/Dart function that finds the next medication time, wrapping to the next day if needed:

```dart
int parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
}

String getNextMedTime(List<String> times, String now) {
    final parsedTimes = times.map(parseTime).toList();
    final nowTime = parseTime(now);
    final nextCandidates = parsedTimes.map((t) => t > nowTime ? t : t + 1440).toList();
    final nextTime = nextCandidates.reduce((a, b) => a < b ? a : b);
    final minutes = nextTime % 1440;
    final hours = (minutes / 60).floor();
    final mins = minutes % 60;
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
}

// Example usage:
void main() {
    print(getNextMedTime(["08:00", "12:00", "16:00"], "23:30")); // "08:00"
    print(getNextMedTime(["23:00"], "23:30")); // "23:00"
    print(getNextMedTime(["00:00", "12:00"], "13:00")); // "00:00"
}
```

## Facts
done_reason: stop  peak GPU: 10519 MiB  placement: fits GPU
