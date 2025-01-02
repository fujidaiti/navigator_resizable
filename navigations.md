## Imperative API

### P1: Initial build (Page A)

```
Restarted application in 263ms.
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): install
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 1.00
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didAdd
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangeNext(<unknown route>)
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangePrevious(<unknown route>)
```

### P2: Navigator.push (Page A -> Page B)

```
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didChangeNext(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false))
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.22
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.33
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.50
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.61
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.72
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.83
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
```

### P3: Navigator.pop (Page B -> Page A)

```
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.89
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.78
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.67
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.56
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.39
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.28
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.17
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.06
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P4: Call Navigator.push twice (Page A -> Page C)

```
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didChangeNext(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false))
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page B(offstage=true, isCurrent=false, isActive=true, isFirst=false))
flutter: Page B(offstage=true, isCurrent=false, isActive=true, isFirst=false): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false))
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.28
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.28
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.33
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.33
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.44
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.50
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.50
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.61
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.61
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.72
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.72
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.83
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.83
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
```

### Navigator.push 3 times

```
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didPush
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didChangeNext(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward))
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didPush
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangeNext(<unknown route>)
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangePrevious(Page B(offstage=true, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=true, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward))
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didPush
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangeNext(<unknown route>)
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangePrevious(Page C(offstage=true, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=true, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward))
flutter: Page D(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page D(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.00
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.00
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.22
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.22
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.22
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.33
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.33
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.33
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.44
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.44
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.56
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.56
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.56
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.61
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.61
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.61
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.72
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.72
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.72
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.83
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.83
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.83
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.94
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
```

### P5: Navigator.popUntil (Page C -> Page A)

```
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPopNext(Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true))
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.89
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.89
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.78
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.78
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.67
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.67
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.56
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.56
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.50
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.50
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.39
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.39
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.28
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.28
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.17
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.17
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.06
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.06
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### Navigator.popUntil (Page D -> Page A)

```
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.status = AnimationStatus.reverse
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didComplete
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didPop
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPopNext(Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse))
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.status = AnimationStatus.reverse
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didComplete
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didPop
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPopNext(Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse))
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didChangePrevious(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.status = AnimationStatus.reverse
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true, AnimationStatus.completed): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse))
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didChangePrevious(Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didChangePrevious(Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.94
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.89
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.89
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.89
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.78
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.78
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.78
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.67
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.67
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.67
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.56
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.56
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.56
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.44
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.44
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.39
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.39
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.39
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.28
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.28
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.28
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.17
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.17
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.17
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.06
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.06
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.06
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
```

### Navigator.push 3 times without animation (Page A -> Page D)

```
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPush
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didChangeNext(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPush
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(<unknown route>)
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): animation.value = 1.00
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPush
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(<unknown route>)
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed))
```

### Navigator.popUntil without animation (Page D -> Page A)

```
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.completed): animation.value = 0.00
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): didComplete
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): didPop
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPopNext(Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed))
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.completed): animation.value = 0.00
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): didComplete
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): didPop
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPopNext(Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.completed): animation.value = 0.00
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true, AnimationStatus.completed): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
```

### P6: Navigator.pushReplacement (Page A -> Page C)

```
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didComplete
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangePrevious(<unknown route>)
flutter: Page A(offstage=false, isCurrent=false, isActive=false, isFirst=false): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true))
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=true): animation.value = 1.00
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.17
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.22
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.33
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.44
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.50
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.61
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.72
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.83
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P7: Swipe back gesture (Page B -> Page A)

```
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.90
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.80
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.70
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.58
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.49
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.39
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.25
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.19
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.09
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): User gesture stopped
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): User gesture stopped
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P8: Swipe back gesture cancelled (Page B -> Page B) 

```
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.89
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.90
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): User gesture stopped
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): User gesture stopped
```

## Declarative API

### P9: Initial build (Page A)

```
Restarted application in 297ms.
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): install
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 1.00
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didAdd
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangeNext(<unknown route>)
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangePrevious(<unknown route>)
```

### Initial build with multiple pages (Page D)

```
Restarted application in 262ms.
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didAdd
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(<unknown route>)
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didAdd
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didAdd
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.dismissed): install
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): animation.value = 1.00
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didAdd
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didChangeNext(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didChangePrevious(<unknown route>)
```

### P17: Push a route without animation (Page A -> Page B)

```
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didChangeNext(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false))
```

### P10: Push a route (Page A -> Page B)

`/a` -> `/b`

```
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didChangeNext(Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false))
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.22
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.33
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.50
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.61
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.72
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.83
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.94
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
```

### P11: Pop a route (Page B -> Page A)

`/a/b` -> `/a`

```
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.89
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.78
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.67
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.56
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.44
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.39
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.28
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.17
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.06
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P18: Pop a route without animation (Page B -> Page A)

`/a/b` -> `/a`

```
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.00
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P12: Push multiple routes at once (Page A -> Page C)

`/a` -> `/a/b/c`

```
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false))
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.28
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.33
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.44
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.50
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.61
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.72
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.83
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): didAdd
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangePrevious(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didChangeNext(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false))
```

### P12: Push multiple routes at once (Page A -> Page D)

```
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didPush
flutter: Page D(offstage=false, sCurrent=true,i isActive=true, isFirst=false, AnimationStatus.forward): didChangeNext(<unknown route>)
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.dismissed): install
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didChangeNext(Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward))
flutter: Page D(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page D(offstage=true, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.00
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.status = AnimationStatus.forward
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.26
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.33
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.44
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.50
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.61
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.72
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.83
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 0.94
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.forward): animation.value = 1.00
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didAdd
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): animation.status = AnimationStatus.completed
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didAdd
flutter: Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page D(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangeNext(Page C(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed): didChangePrevious(Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true, AnimationStatus.completed): didChangeNext(Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false, AnimationStatus.completed))
```


### P13: Pop multiple routes at once (Page C -> Page A)

`/a/b/c` -> `/a`

```
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPopNext(Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): didChangePrevious(Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true))
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.89
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.78
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.67
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.56
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.50
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.39
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.28
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.17
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.06
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P13: Pop multiple routes at once (Page D -> Page A)

```
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.status = AnimationStatus.reverse
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didComplete
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didPop
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didComplete
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didPopNext(Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse))
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false, AnimationStatus.completed): didComplete
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): didChangePrevious(Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true, AnimationStatus.completed))
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true, AnimationStatus.completed): didChangeNext(<unknown route>)
flutter: Page C(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.completed): dispose
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.completed): dispose
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.78
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.67
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.56
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.50
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.39
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.28
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.17
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.reverse): animation.value = 0.06
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): animation.status = AnimationStatus.dismissed
flutter: Page D(offstage=false, isCurrent=false, isActive=false, isFirst=false, AnimationStatus.dismissed): dispose
```

### P14: Replace the entire navigation stack (Page B -> Page C)

`/a/b` -> `/c`

```
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): install
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didPush
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=false): didChangeNext(<unknown route>)
flutter: Page B(offstage=false, isCurrent=false, isActive=true, isFirst=false): didComplete
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): didComplete
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): didChangePrevious(<unknown route>)
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didChangePrevious(<unknown route>)
flutter: Page A(offstage=false, isCurrent=false, isActive=false, isFirst=false): didChangeNext(Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true))
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=true): animation.value = 1.00
flutter: Page C(offstage=true, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.completed
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.forward
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.11
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.22
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.33
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.44
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.56
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.61
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.72
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.83
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 0.94
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.value = 1.00
flutter: Page C(offstage=false, isCurrent=true, isActive=true, isFirst=true): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P15: Swipe back gesture (Page B -> Page A)

```
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.90
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.80
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.70
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.59
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.50
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.39
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.26
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.reverse
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didComplete
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): didPop
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): didPopNext(Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false))
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.16
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.value = 0.10
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): animation.status = AnimationStatus.dismissed
flutter: Page A(offstage=false, isCurrent=true, isActive=true, isFirst=true): User gesture stopped
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): User gesture stopped
flutter: Page B(offstage=false, isCurrent=false, isActive=false, isFirst=false): dispose
```

### P16: Swipe back gesture cancelled (Page B -> Page B)

```
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): User gesture started
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.forward
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.90
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.80
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.80
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 0.92
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.value = 1.00
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): animation.status = AnimationStatus.completed
flutter: Page A(offstage=false, isCurrent=false, isActive=true, isFirst=true): User gesture stopped
flutter: Page B(offstage=false, isCurrent=true, isActive=true, isFirst=false): User gesture stopped
```

## Notes

```code
isInitialRoute = didAdd(isCurrent=true, AnimationStatus.completed) && previousCurrentRoute == null;
wasPopped = didChangePrevious(isCurrent=false, wasCurrent=true, AnimationStatus.reverse, previousRoute.isCurrent=true)
wasPoppedWithoutTransition = didPop(wasCurrent=true, AnimationStatus.completed, previousRoute.isCurrent=true)
```
