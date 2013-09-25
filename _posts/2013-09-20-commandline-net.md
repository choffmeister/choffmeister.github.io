---
layout:     post
title:      "Parsing command-line arguments with C#"
date:       2013-09-20 21:00:01
categories: csharp
---

In the last time I often build command-line tools with C# that needed some parsing of the command-line arguments passed in. Often I just have done simple comparison of strings to detect the arguments. Since doing everything the same incomplete crap is bad, I build a simple library called DotArguments to handle that stuff. It allows defining the arguments, types etc via a simple POCO argument container class with some attributes.

The library is heavily unit tested and rock solid. It can be found at [DotArguments](https://github.com/choffmeister/DotArguments) and licensed under the permissive MIT license. Feel free to use it or contribute. My next plan is to implement some simple code, to generate usage instructions from the POCO argument container.

You can easily install the package via [NuGet](http://www.nuget.org/packages/DotArguments/).

## Example

```csharp
using System;
using DotArguments;
using DotArguments.Attributes;

namespace DotArgumentsDemo
{
    public class DemoArguments
    {
        [PositionalValueArgument(0, "inputpath")]
        [ArgumentDescription(Short = "the input path")]
        public string InputPath { get; set; }

        [PositionalValueArgument(1, "outputpath", IsOptional = true)]
        [ArgumentDescription(Short = "the output path")]
        public string OutputPath { get; set; }

        [NamedValueArgument("name", 'n', IsOptional = true)]
        [ArgumentDescription(Short = "the name")]
        public string Name { get; set; }

        [NamedValueArgument("age", IsOptional = true)]
        [ArgumentDescription(Short = "the age")]
        public int? Age { get; set; }

        [NamedSwitchArgument("verbose", 'v')]
        [ArgumentDescription(Short = "enable verbose console output")]
        public bool Verbose { get; set; }

        [RemainingArguments]
        public string[] RemainingArguments { get; set; }
    }

    public class Program
    {
        public static void Main(string[] args)
        {
            // create container definition
            ArgumentDefinition definition = new ArgumentDefinition(typeof(DemoArguments));

            try
            {
                // create object with the populated arguments
                DemoArguments arguments = definition.Parse<DemoArguments>(args);

                Console.WriteLine("InputPath: {0}", arguments.InputPath ?? "(null)");
                Console.WriteLine("OutputPath: {0}", arguments.OutputPath ?? "(null)");
                Console.WriteLine("Name: {0}", arguments.Name ?? "(null)");
                Console.WriteLine("Age: {0}", arguments.Age.HasValue ? arguments.Age.Value.ToString() : "(null)");
                Console.WriteLine("Verbose: {0}", arguments.Verbose);
                Console.WriteLine("Remaining: [{0}]", string.Join(",", arguments.RemainingArguments));

                Environment.Exit(0);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(string.Format("error: {0}", ex.Message));
                Console.Error.Write(string.Format("usage: {0}", definition.GenerateUsageString()));

                Environment.Exit(1);
            }
        }
    }
}
```

Here are some examples, how the application can be invoked and what values would be populated:

```bash
$ DotArguments.Demo.exe --age 10 --name tom input output
InputPath: input
OutputPath: output
Name: tom
Age: 10
Verbose: False
Remaining: []
```

```bash
$ DotArguments.Demo.exe --name tom output --age 10
InputPath: output
OutputPath: (null)
Name: tom
Age: 10
Verbose: False
Remaining: []
```

```bash
$ DotArguments.Demo.exe input -v output additional1 additional2
InputPath: input
OutputPath: output
Name: (null)
Age: (null)
Verbose: True
Remaining: [additional1,additional2]
```

Are invocation with invalid arguments:

```bash
DotArguments.Demo.exe
error: Mandatory argument at position 0 is missing
usage: DotArguments.Demo.exe [options] inputpath [outputpath] [...]

  inputpath          the input path
  outputpath         the output path

  --age              the age
  -n, --name         the name
  -v, --verbose      enable verbose console output
```
