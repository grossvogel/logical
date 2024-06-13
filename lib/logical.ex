defmodule Logical do
  @moduledoc """
  A module to evaluate mathematical and logic expressions encoded as data.
  To support JSON serialization, all expressions are lists, using a lisp-style syntax

  """

  @type result :: number() | binary() | boolean()
  @type expression :: result() | list()

  defguard is_base_value(expression)
           when is_binary(expression) or is_number(expression) or is_boolean(expression) or
                  is_struct(expression, Date) or
                  is_struct(expression, NaiveDateTime)

  @doc """
  Evaluate an expression

  ## Examples

      iex> Logical.eval(11)
      11

      iex> Logical.eval(11.22)
      11.22

      iex> Logical.eval("hello")
      "hello"

      iex> Logical.eval(["+", 1, 2])
      3

      iex> Logical.eval(["+", 1, 2, 3, 4])
      10

      iex> Logical.eval(["*", 2, 3])
      6

      iex> Logical.eval(["*", 2, 3, 4])
      24

      iex> Logical.eval(["-", 5, 3])
      2

      iex> Logical.eval(["/", 5, 2])
      2.5

      iex> Logical.eval(["+", ~N[2000-01-20 23:00:28], [3, "days"]])
      ~N[2000-01-23 23:00:28]

      iex> Logical.eval(["+", ~N[2000-01-20 23:00:28], [3, "minute"]])
      ~N[2000-01-20 23:03:28]

      iex> Logical.eval(["+", ~D[2000-01-20], [3, "days"]])
      ~D[2000-01-23]

      iex> Logical.eval(["-", ~N[2000-01-20 23:00:28], [3, "days"]])
      ~N[2000-01-17 23:00:28]

      iex> Logical.eval(["-", ~N[2000-01-20 23:00:28], [3, "minute"]])
      ~N[2000-01-20 22:57:28]

      iex> Logical.eval(["-", ~D[2000-01-20], [3, "days"]])
      ~D[2000-01-17]

      iex> ["-", "today", [180, "days"]] |> Logical.eval() |> is_struct(Date)
      true

  """
  @spec eval(expression()) :: result()

  # raw values... binaries that have special meanings must come first
  def eval("now"), do: NaiveDateTime.utc_now()

  def eval("today"), do: Date.utc_today()

  def eval(expression) when is_base_value(expression), do: expression

  def eval([n, "second" <> _]), do: {eval(n), :second}
  def eval([n, "minute" <> _]), do: {eval(n), :minute}
  def eval([n, "hour" <> _]), do: {eval(n), :hour}
  def eval([n, "day" <> _]), do: {eval(n), :day}

  # arithmetic
  def eval(["+", expression_a]) do
    eval(expression_a)
  end

  def eval(["+", expression_a, expression_b | rest]) do
    eval(["+", add(eval(expression_a), eval(expression_b)) | rest])
  end

  def eval(["*", expression_a]) do
    eval(expression_a)
  end

  def eval(["*", expression_a, expression_b | rest]) do
    eval(["*", multiply(eval(expression_a), eval(expression_b)) | rest])
  end

  def eval(["-", expression_a, expression_b]) do
    subtract(eval(expression_a), eval(expression_b))
  end

  def eval(["/", expression_a, expression_b]) do
    divide(eval(expression_a), eval(expression_b))
  end

  defp add(a, b) when is_number(a) and is_number(b), do: a + b

  defp add(date_time, {amount, interval})
       when is_struct(date_time, NaiveDateTime) and is_integer(amount) and
              interval in [:day, :hour, :minute, :second],
       do: NaiveDateTime.add(date_time, amount, interval)

  defp add(date, {amount, :day})
       when is_struct(date, Date) and is_integer(amount),
       do: Date.add(date, amount)

  defp add({n, interval}, date_or_datetime)
       when is_struct(date_or_datetime, Date) or is_struct(date_or_datetime, NaiveDateTime),
       do: add(date_or_datetime, {n, interval})

  defp multiply(a, b) when is_number(a) and is_number(b), do: a * b

  defp divide(a, b) when is_number(a) and is_number(b), do: a / b

  defp subtract(a, b) when is_number(a) and is_number(b), do: a - b

  defp subtract(date_time, {amount, interval})
       when is_struct(date_time, NaiveDateTime) and is_integer(amount) and
              interval in [:day, :hour, :minute, :second],
       do: NaiveDateTime.add(date_time, -amount, interval)

  defp subtract(date, {amount, :day})
       when is_struct(date, Date) and is_integer(amount),
       do: Date.add(date, -amount)

  defp subtract({n, interval}, date_or_datetime)
       when is_struct(date_or_datetime, Date) or is_struct(date_or_datetime, NaiveDateTime),
       do: subtract(date_or_datetime, {n, interval})
end
