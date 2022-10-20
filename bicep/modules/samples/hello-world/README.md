# Hello World

A sample template

## Description

Sample Module to establish a template for future modules.

## Parameters

| Name   | Type     | Required | Description                       |
| :----- | :------: | :------: | :-------------------------------- |
| `name` | `string` | Yes      | The name of someone to say hi to. |

## Outputs

| Name     | Type   | Description        |
| :------- | :----: | :----------------- |
| greeting | string | The hello message. |

## Examples

```bicep
module helloWorld 'br/osdubicep.azurecr.io:samples/hello-world:1.0.1' = {
  name: 'helloWorld'
  params: {
    name: 'Bicep developers'
  }
}

output greeting string = helloWorld.outputs.greeting
```