# JSON Transformer

Use JSON to turn JSON into JSON

This is a proof-of-concept for a means of transforming JSON that may become a full-fledged spec someday. It's like XSLT, but for JSON!

A transformation requires two JSON documents: an _input_ document and a _rules_ document. The input document is the source of your data, and the rules document describes how to transform your data to return the desired output. Your input and your rules **must** both be valid JSON objects.

A rules document is designed to resemble the desired output; a simple rules document applied to _any_ source may simply return your rules document. For example, this is a valid rules document that is not affected by an input document; running this rules document through the transformer will simply return itself, regardless of your input:

    { "hello": "world" }

Strings in your rules document can take the form of a JSON Path, in which case they will be replaced with whatever data exists at the specified path in your input document:

    // input
    { "message": "Hello world" }

    // rules
    { "foobar": "$.message" }

    // output
    { "foobar": "Hello world" }

You can also create repeating objects by adding a special `$each` key to an object in your rules document. The value of an `$each` key should be a JSON Path pointing to an array or object in your input document. The `$each` key's parent object will then be repeated once for each member of the array or object found, creating an object whose keys match the keys that are siblings of your `$each` key. (The `$each` key will not be preserved in your output document). If any of the `$each` key's sibling's values are JSON Paths, they will be evaluated relative to the current item from the array or object being used to generate your result.

    // input
    {
      "items": [
        { "type": "a", "id": 1 },
        { "type": "b", "id": 2 },
        { "type": "c", "id": 3 }
      ]
    }

    // rules
    {
      "result": {
        "$each": "$.items",
        "kind": "$.kind",
        "id": "$.id"
      }
    }

    // output
    {
      "result": [
        { "kind": "a", "id": 1 },
        { "kind": "b", "id": 2 },
        { "kind": "c", "id": 3 }
      ]
    }

Your `$each` key's path can also include wildcards! These will be expanded so that your resulting object contains all possible values from your input doc, and you can use your wildcard value in each item as well using a named capture.

    // input
    {
      "silverware": {
        "forks": [
          {
            "skuId": "7fdd8",
            "quality": "good"
          }
        ],
        "spoons": [
          {
            "skuId": "ca733",
            "quality": "great"
          }
        ],
        "knives": [
          {
            "skuId": "94033",
            "quality": "knifey"
          }
        ]
      }
    }

    // rules
    {
      "data": {
        "$each": "$.silverware.:type",
        "id": "$.skuId",
        "type": ":type",
        "quality": "$.quality"
      }
    }

    // output
    {
      "data": [
        {
          "id": "7fdd8",
          "type": "forks",
          "quality": "good"
        },
        {
          "id": "ca733",
          "type": "spoons",
          "quality": "great"
        },
        {
        {
          "id": "94033",
          "type": "knives",
          "quality": "knifey"
        }
      ]
    }

