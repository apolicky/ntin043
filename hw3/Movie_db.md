# Movie database

## Poznamky

* 1 invariant
* 1 pre-condition
* 1 post-condition
* 1 default value -- init
* once select/reject
* once forAll/exists
* once size

### 1 invariant

```ocl
context: Rating
inv: self.stars <= 0 and self.stars >= 5
```

### 1 pre-condition

### 1 post-condition

```ocl
context: Viewer::getRatedMovies() : set (Movie)
pre: -- none
post: result = self.
```

### 1 default value

```ocl
context: Creator::awards
init: Set {}
```

### once select/reject

```ocl
context: Movie::rating : Real
derive: self.
```

### once forAll/exists

```ocl

```

### once size

```ocl
context: Movie
inv: self.givenRating->size() <= collect(Viewer)
```