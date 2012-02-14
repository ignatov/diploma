[<Generate>]
type T = Microsoft.FSharp.Data.TypeProviders.
DbmlFile< @"DataClasses.dbml" >
let typeDBMLProvider() =
    let db = new T.DataClasses1DataContext(
    "Data Source=localhost;Initial Catalog=FSharpSample;User ID=sa;Password=1234")
    let q = query {
        for n in db.Students do
        select n.Name }
    q |> Seq.iter (fun n -> printfn "student name = %s" n)