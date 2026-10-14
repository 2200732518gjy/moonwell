///|
test "protocol validates typed fields and returns one JSON envelope" {
  let request = Json::object({
    "command": Json::string("qa"),
    "las": Json::string(write_las(fixture())),
    "max_gap": Json::number(2.0),
  })
  let result = execute(request.stringify())
  assert_true(result.contains("\"ok\":true"))
  assert_true(result.contains("moonwell.qa/v1"))
  assert_true(execute("{bad}").contains("\"ok\":false"))
  assert_true(
    execute("{\"command\":\"qa\",\"extra\":1}").contains(
      "unknown request field",
    ),
  )
  assert_true(execute("{\"command\":\"erase\"}").contains("unknown command"))
}

///|
test "protocol assembles runs with explicit configuration" {
  let run = Json::object({
    "name": Json::string("one"),
    "las": Json::string(write_las(fixture())),
  })
  let request = Json::object({
    "command": Json::string("assemble"),
    "runs": Json::array([run]),
    "start": Json::number(0.0),
    "stop": Json::number(2.0),
    "step": Json::number(1.0),
    "max_gap": Json::number(2.0),
    "policy": Json::string("reject"),
    "tolerance": Json::number(0.0),
  })
  assert_true(execute(request.stringify()).contains("moonwell.assembly/v1"))
}
