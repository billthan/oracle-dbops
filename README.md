# DBOps (Oracle) 

This repository is configured to take snapshots of database object DDLs. This is to assist with the tracking database changes over time. 


# Usage

Create the folder structure

```
./create_dirs.sh
```


Clean any previous runs

```
./rm_sql_clean.sh
```

To run DDL export, run the `EXPORT_DDL_DRIVER.sql` in Oracle as `dba` 

# Contributors

* Bill Than
* [Nathan Ackerson](https://www.linkedin.com/in/nathan-ackerson-66aa68197)
* [Joshua Wry](https://www.linkedin.com/in/jw1999/)
