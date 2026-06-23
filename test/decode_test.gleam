import gleam/dynamic/decode
import gleam/list
import gleam/option
import yum/yaml

type Job {
  Job(
    name: String,
    script: List(String),
    image: option.Option(String),
    retries: Int,
  )
}

pub fn decode_nested_record_with_list_and_optional_fields_test() {
  let input =
    "job:
  name: test
  script:
    - gleam test
    - gleam format
  image: null
"

  let decoder = {
    use job <- decode.field("job", job_decoder())
    decode.success(job)
  }

  assert yaml.decode(input, using: decoder)
    == Ok(Job(
      name: "test",
      script: ["gleam test", "gleam format"],
      image: option.None,
      retries: 1,
    ))
}

pub fn decode_at_retrieves_nested_sequence_values_test() {
  let input =
    "job:
  script:
    - gleam test
    - gleam format
"

  assert yaml.decode(
      input,
      using: decode.at(["job", "script"], decode.list(of: decode.string)),
    )
    == Ok(["gleam test", "gleam format"])
}

pub fn decode_returns_type_failures_from_dynamic_decoder_test() {
  let decoder = {
    use count <- decode.field("count", decode.int)
    decode.success(count)
  }

  let assert Error(yaml.UnableToDecode(errors)) =
    yaml.decode("count: many", using: decoder)

  assert list.length(errors) == 1
}

fn job_decoder() -> decode.Decoder(Job) {
  use name <- decode.field("name", decode.string)
  use script <- decode.field("script", decode.list(of: decode.string))
  use image <- decode.optional_field(
    "image",
    option.None,
    decode.optional(decode.string),
  )
  use retries <- decode.optional_field("retries", 1, decode.int)

  decode.success(Job(name:, script:, image:, retries:))
}
