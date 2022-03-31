---
boolean_metadata_false: false
boolean_metadata_true: true
number_metadata: 42
string_metadata: a string
title: Test document for *panda*
---

# Expansion

Input file: test/test.md

Output file: .build/test.md

``` lua
-- normal code block
-- foo = bar
-- bar = The title is: Test document for panda
-- baz = {{baz}}
-- email = [my email](me@example.com)
-- email2 = me2@example.com
```

-   title = "Test document for panda"
-   string_metadata = a string (a string) a string, a string.
-   boolean_metadata_true = true
-   boolean_metadata_false = false
-   number_metadata = 42
-   foo = bar (bar) bar, bar.
-   bar = The title is: Test document for panda
-   baz = {{baz}}
-   email = [my email](me@example.com)
-   email2 = [eMail](mailto:me2@example.com)

::: { foo = bar } :::

[bar](bar/index.html)

## Header { foo = bar } {#header-foo-foo}

# Conditional blocks

## Comments

## Condition

<div>

foo is bar

</div>

<div>

`number_medatata` is 42

</div>

<div>

`boolean_metadata_false` is false

</div>

<div>

`string_metadata` is `"a string"`

</div>

Also works for inline spans. foo is bar and `string_metadata` is
`"a string"`

# File inclusion

``` c
int main(void)
{
    return 0;
}

/* foo */
```

    main = {
        return 0;
    }

## Title of the included file

Content of the included file (foo = bar)

# Scripts

``` class
Pandoc is great!
```

1 + 1 = `2`

1 + 1 = 2

# Diagrams

![Alice & Bob](.build/img/panda_plantuml_test.svg "Alice & Bob")

[![Alternative
description](.build/cache/0ec62f1568ac33e20ec8d430ae77a9cbe6c9cd46.svg "Alice & Bob")](http://example.com "Alice & Bob")
