```
rs.initiate( 
        {
          _id : "ssdclopezpro",
          members: [
              { _id: 0, host: "mongodb:27017",priority: 2 },
              { _id: 1, host: "db_secundary:27017",priority: 1 }
          ]
        })
rs.reconfig( 
        {
          _id : "ssdclopezpro",
          members: [
              { _id: 0, host: "mongodb:27017",priority: 2 },
              { _id: 1, host: "db_secundary:27019",priority: 1 }
          ]
        },{force:true})
```
