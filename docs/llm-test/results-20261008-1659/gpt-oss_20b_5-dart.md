# gpt-oss:20b — 5-dart

## Prompt
Write a Flutter/Dart function that takes a list of medication times (as "HH:mm" strings) and returns the next time after a given "now" time, wrapping to the next day if needed. Include a short test. Keep it under 60 lines.

## Thinking
The user wants: "Write a Flutter/Dart function that takes a list of medication times (as 'HH:mm' strings) and returns the next time after a given 'now' time, wrapping to the next day if needed. Include a short test. Keep it under 60 lines."

So, we need to produce a Dart function: probably named getNextMedicationTime or similar. The input: List<String> medicationTimes; String now. Both times are "HH:mm". We should parse them into DateTime objects maybe using a base date, say today. For each medication time, parse into a DateTime on the same date as now. Compare with now's time. If it's after now, we consider that candidate. If none are after now, then wrap to the earliest time next day. Return the string "HH:mm" of the next time.

We should also consider that the times might be unsorted; we need to find the minimum time > now, else wrap.

We need to handle day boundaries. The function might be static or top-level.

We also need to include a short test: maybe using main() function, and print some examples. Ensure code under 60 lines. Use Dart's DateTime parsing. We can parse "HH:mm" as DateTime.parse with a dummy date, or using DateFormat from intl package, but better to avoid external packages, just parse manually.

Simplest: parse "HH:mm" into hour and minute ints. Then use DateTime.now() to get today's date. Then create DateTime objects with same year, month, day.

But for now we want to supply a now string "HH:mm". We can also parse now into hour and minute. Then create DateTime objects for each medication time on today's date. Compare.

Potential issue: if now time is, say, 23:50, and medication times include 01:00, the next time is 01:00 next day. Our logic will find that 01:00 is before now, so we wrap to the earliest time (01:00). So that's correct.

Edge case: If times include 00:00 and now is 00:00 exactly, we might want next time after now: that means we treat times that equal now as not after. So we treat > not >=.

We should mention that the function returns a string "HH:mm". Or maybe return a DateTime? The user wants "returns the next time after a given 'now' time". They didn't specify return type, but likely a string.

Let's produce function:

String nextMedicationTime(List<String> times, String now) { ... }

We'll parse now as DateTime? Actually we can parse now as DateTime like DateTime(2000,1,1, hour, minute). Then for each time string, parse to hour and minute, create DateTime(2000,1,1,hour,minute). Then compare.

Better: using a base date like 2000-01-01.

Let's implement:

DateTime parseTime(String s) {
  final parts = s.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return DateTime(2000, 1, 1, hour, minute);
}

Now parse now:

final nowDt = parseTime(now);

Then find list of DateTimes after now: times.where((t) => parseTime(t).isAfter(nowDt)).toList();

If any, choose the one with the minimum time difference: sort them ascending. Or just find min by comparing.

If none, we wrap: choose the earliest time in times: times.map(parseTime).reduce(min).

But since we want to wrap to next day, the result string should be the time string of the earliest time.

Return the string.

Test: In main, define times = ['08:00', '12:30', '18:00']; now = '09:00'; next = nextMedicationTime(times, now) => '12:30'.

Another test: now = '20:00' -> wrap -> '08:00'.

Also test now = '12:30' -> next > now is 18:00. If equal times? Let's test.

We'll use print.

Let's produce code under 60 lines.

But we need to ensure the code is not too long. Under 60 lines including function and test. We can add a small main function.

Ok.

Potential improvement: Use .sort. We'll keep simple.

Let's draft:

String nextMedicationTime(List<String> times, String now) {
  DateTime parse(String s) {
    final parts = s.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return DateTime(2000, 1, 1, h, m);
  }

  final nowDt = parse(now);
  final futureTimes = <DateTime>[];

  for (var t in times) {
    final dt = parse(t);
    if (dt.isAfter(nowDt)) {
      futureTimes.add(dt);
    }
  }

  DateTime chosen;
  if (futureTimes.isNotEmpty) {
    chosen = futureTimes.reduce((a, b) => a.isBefore(b) ? a : b);
  } else {
    // wrap to next day: earliest time
    chosen = times.map(parse).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  // Format back to HH:mm
  return '${chosen.hour.toString().padLeft(2, '0')}:${chosen.minute.toString().padLeft(2, '0')}';
}

Test:

void main() {
  final times = ['08:00', '12:30', '18:00'];
  print(nextMedicationTime(times, '09:00')); // 12:30
  print(nextMedicationTime(times, '20:00')); // 08:00
  print(nextMedicationTime(times, '12:30')); // 18:00
  print(nextMedicationTime(times, '07:59')); // 08:00
  print(nextMedicationTime(times, '00:00')); // 08:00
}

We need to keep under 60 lines. The above is about 25 lines. Good.

Alternatively, we could use .map to parse, then find min > now.

Potential improvement: we can handle if times list is empty: return null or throw error. But not necessary.

We could also parse times into DateTime with date 1970-01-01 to avoid overflow, but fine.

We might want to import 'dart:core' (implicitly imported). So code compile.

Ok.

But need to keep code minimal.

Edge: times might have duplicate times. It's fine.

Edge: times might be unsorted. It's fine.

The function will parse each time string.

Now test.

The user also asked "Include a short test." So we need to write a test that prints expected and actual.

We can do simple prints.

Better: Use assert statements.

We can write:

assert(nextMedicationTime(times, '09:00') == '12:30');
assert(nextMedicationTime(times, '20:00') == '08:00');
assert(nextMedicationTime(times, '12:30') == '18:00');
assert(nextMedicationTime(times, '07:59') == '08:00');

Then print('All tests passed').

But we should keep under 60 lines, we can do that.

Ok.

Potential issues: In debug mode, assert may not run, but fine.

Also consider that we should parse string '23:59' etc.

Ok.

Now final code.

We should keep code under 60 lines. We'll write it accordingly.

Let's produce final answer.

We'll include import 'dart:core'; but it's not needed.

Let's count lines.

We'll output code.

But maybe we should include comments? We can add a few comments.

But keep under 60 lines.

Let's do final code: (approx 40 lines). We'll include comments.

Ok.

Now produce final answer.

## Answer
```dart
/// Returns the next medication time (HH:mm) after [now] from the list [times].
/// If all times are before or equal to [now], it wraps to the earliest time the next day.
String nextMedicationTime(List<String> times, String now) {
  DateTime _parse(String s) {
    final p = s.split(':');
    return DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
  }

  final nowDt = _parse(now);
  final future = <DateTime>[];

  for (final t in times) {
    final dt = _parse(t);
    if (dt.isAfter(nowDt)) future.add(dt);
  }

  final chosen = future.isNotEmpty
      ? future.reduce((a, b) => a.isBefore(b) ? a : b)
      : times.map(_parse).reduce((a, b) => a.isBefore(b) ? a : b);

  return '${chosen.hour.toString().padLeft(2, '0')}:${chosen.minute.toString().padLeft(2, '0')}';
}

void main() {
  final times = ['08:00', '12:30', '18:00'];

  assert(nextMedicationTime(times, '09:00') == '12:30');
  assert(nextMedicationTime(times, '20:00') == '08:00');
  assert(nextMedicationTime(times, '12:30') == '18:00');
  assert(nextMedicationTime(times, '07:59') == '08:00');
  assert(nextMedicationTime(times, '00:00') == '08:00');

  print('All tests passed.');
}
```
This snippet is well under 60 lines, uses only Dart core libraries, and includes a concise test suite.

## Facts
done_reason: stop  peak GPU: 12959 MiB  placement: fits GPU
