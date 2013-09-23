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
        [PositionalValueArgument(0)]
        public string InputPath { get; set; }

        [PositionalValueArgument(1, IsOptional = true)]
        public string OutputPath { get; set; }

        [NamedValueArgument("name", 'n', IsOptional = true)]
        public string Name { get; set; }

        [NamedValueArgument("age", 'a', IsOptional = true)]
        public int? Age { get; set; }

        [NamedSwitchArgument("verbose", 'v')]
        public bool Verbose { get; set; }
    }

    public class Program
    {
        public static void Main(string[] args)
        {
            try
            {
                // create object with the populated arguments
                DemoArguments arguments = ArgumentParser<DemoArguments>.Parse(args);

                Console.WriteLine("InputPath: {0}", arguments.InputPath ?? "(null)");
                Console.WriteLine("OutputPath: {0}", arguments.OutputPath ?? "(null)");
                Console.WriteLine("Name: {0}", arguments.Name ?? "(null)");
                Console.WriteLine("Age: {0}", arguments.Age.HasValue ? arguments.Age.Value.ToString() : "(null)");
                Console.WriteLine("Verbose: {0}", arguments.Verbose);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex);
            }
        }
    }
}
```

Here are some examples, how the application can be invoked and what values would be populated:

```bash
$ DotArgumentsDemo.exe -a 10 --name tom input output
InputPath: input
OutputPath: output
Name: tom
Age: 10
Verbose: False
```

```bash
$ DotArgumentsDemo.exe input --name tom output -a 10
InputPath: input
OutputPath: output
Name: tom
Age: 10
Verbose: False
```

```bash
$ DotArgumentsDemo.exe input --verbose -a 10
InputPath: input
OutputPath: (null)
Name: (null)
Age: 10
Verbose: True
```

```bash
$ DotArgumentsDemo.exe input -v output
InputPath: input
OutputPath: output
Name: (null)
Age: (null)
Verbose: True
```

