# Development Notes

## System Object Descriptions

1. Users - Managed via devise, used to determine whether someone can alter link objects and add or delete users.

2. Links - These are just labels and URLs.  Basically never considered as individual objects.

3. LinkLists - Central data managed by this tool.  They are a collection of links and metadata about the collection.

4. Metadata - A wrapper object for MODS metadata fetched from external services (non-persisted)

## Import Format

ListView can import records from .csv or .xlsx files.  These files are broadly separated into a header section and a content section.  The header section contains metadata about the LinkList, while the content section contains labels and URLs for the individual links.  Examples are provided in [test/data](test/data).

### Header
The header consists of all rows until CONTENT_LIST marker.

The first row of the spreadsheet must be:

|  1        | 2    |
| --------- | ----- |
|  \<blank\>  | URL  |

Where URL is a link to the link list's Hollis record.

Following the first row, blank rows are skipped. Header rows are processed specially, based on the values in their first cell.

* `FTS_Search` - URL pointing at full text search for a record:

    |  1           | 2                                                    |
    | ------------ | ------------------------------------------------------ |
    |  FTS_Search  | http://fts.lib.harvard.edu/fts/search?Q=boston&S=HLR |

* `Continues:` or `Continued by:` are processed as continuation links, and follow the structure:

    | 1                  | 2     | 3   |
    | -------------------- | ------- | ----- |
    | Continue(ed by\|s): | label | URL |

* `FTS_NoDate` the `FTS_Search` for this record does not allow date qualification

    |  1           |  2  |
    | ------------ | --- |
    |  FTS_NoDate  |  \<blank\>   |


* Any other header rows are treated as display metadata, and should take the form:

    |  1       |  2        |
    | -------- | --------- |
    |  label:  |  content  |

### CONTENT_LIST marker
`CONTENT_LIST` in the first column with an empty second column.

|  1              |  2  |
| --------------- | --- |
|  CONTENT_LIST   | \<blank\>    |

### Links
Links consist of labels and URLs.  Should take the form:

|  1      |  2    |
| ------- | ----- |
|  label  |  URL  |

Example:

|  1                                                  |  2                                               |
| --------------------------------------------------- | ------------------------------------------------ |
|  Harvard Law Record, vol. 3, no. 3 (March 5, 1947)  |  http://nrs.harvard.edu/urn-3:HLS.LIBR:10646916  |
