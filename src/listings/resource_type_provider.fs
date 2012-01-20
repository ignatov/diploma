[<Generate>]
type T = Microsoft.FSharp.Data.TypeProviders.ResxFile< @"Resource.resx" >

let typeResxProviderTest() = 
    printfn "string1 from resource is %s" T.Resource.String1
    printfn "string2 from resource is %s" T.Resource.String2