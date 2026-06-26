import gleamgen/expression
import gleamgen/expression/case_
import gleamgen/internal/render
import gleamgen/pattern

pub fn list_with_literals_test() {
  let result =
    pattern.list([pattern.string_literal("a"), pattern.string_literal("b")])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[\"a\", \"b\"]"

  assert result == expected
}

pub fn list_with_variables_test() {
  let result =
    pattern.list([pattern.variable("x"), pattern.variable("y")])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[x, y]"

  assert result == expected
}

pub fn list_empty_test() {
  let result =
    pattern.list([])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[]"

  assert result == expected
}

pub fn list_with_single_literal_test() {
  let result =
    pattern.list([pattern.string_literal("a")])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[\"a\"]"

  assert result == expected
}

pub fn list_with_discards_test() {
  let result =
    pattern.list([pattern.discard(), pattern.discard()])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[_, _]"

  assert result == expected
}

pub fn list_with_ints_test() {
  let result =
    pattern.list([pattern.int_literal(1), pattern.int_literal(2)])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[1, 2]"

  assert result == expected
}

pub fn list_with_named_rest_test() {
  let result =
    pattern.list_with_named_rest([pattern.variable("x")], "rest")
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[x, ..rest]"

  assert result == expected
}

pub fn list_with_rest_discard_test() {
  let result =
    pattern.list_with_rest_discard([pattern.variable("first")])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[first, ..]"

  assert result == expected
}

pub fn list_with_named_rest_empty_test() {
  let result =
    pattern.list_with_named_rest([], "items")
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[..items]"

  assert result == expected
}

pub fn list_with_rest_discard_empty_test() {
  let result =
    pattern.list_with_rest_discard([])
    |> pattern.to_dynamic
    |> pattern.render(render.default_context(), 1)
    |> render.to_string()

  let expected = "[..]"

  assert result == expected
}

pub fn list_in_case_expression_test() {
  let result =
    case_.new(expression.list([
      expression.string("hello"),
      expression.string("world"),
    ]))
    |> case_.with_pattern(
      pattern.list([pattern.variable("a"), pattern.variable("b")]),
      fn(outputs) {
        let assert [a, b] = outputs
        expression.concat_string(a, b)
      },
    )
    |> case_.with_pattern(pattern.variable("_"), fn(_) {
      expression.string("fallback")
    })
    |> case_.build_expression()
    |> expression.render(render.default_context())
    |> render.to_string()

  let expected =
    "case [\"hello\", \"world\"] {
  [a, b] -> a <> b
  _ -> \"fallback\"
}"

  assert result == expected
}

pub fn list_with_named_rest_in_case_expression_test() {
  let result =
    case_.new(expression.list([
      expression.string("hello"),
      expression.string("world"),
    ]))
    |> case_.with_pattern(
      pattern.list_with_named_rest([pattern.variable("x")], "rest"),
      fn(outputs) {
        let assert [x, rest] = outputs
        expression.concat_string(x, expression.coerce_dynamic_unsafe(
          expression.call_dynamic(
            expression.raw("string.join") |> expression.to_dynamic,
            [rest |> expression.to_dynamic, expression.string(",") |> expression.to_dynamic],
          ),
        ))
      },
    )
    |> case_.with_pattern(pattern.variable("_"), fn(_) {
      expression.string("fallback")
    })
    |> case_.build_expression()
    |> expression.render(render.default_context())
    |> render.to_string()

  let expected =
    "case [\"hello\", \"world\"] {
  [x, ..rest] -> x <> string.join(rest, \",\")
  _ -> \"fallback\"
}"

  assert result == expected
}

pub fn list_with_rest_discard_in_case_expression_test() {
  let result =
    case_.new(expression.list([
      expression.string("hello"),
      expression.string("world"),
    ]))
    |> case_.with_pattern(
      pattern.list_with_rest_discard([pattern.variable("x")]),
      fn(outputs) {
        let assert [x] = outputs
        expression.concat_string(x, expression.string("_suffix"))
      },
    )
    |> case_.with_pattern(pattern.variable("_"), fn(_) {
      expression.string("fallback")
    })
    |> case_.build_expression()
    |> expression.render(render.default_context())
    |> render.to_string()

  let expected =
    "case [\"hello\", \"world\"] {
  [x, ..] -> x <> \"_suffix\"
  _ -> \"fallback\"
}"

  assert result == expected
}
