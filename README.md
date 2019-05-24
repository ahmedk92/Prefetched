# Prefetched

## What

A small class that wraps a value to be **quickly** fetched asynchronously, while offering to block until that value is fetched.

## Why
Some values (usually expected to be in a collection) are costly to be fetched all on the main thread (or generally, the calling thread). 
So, fetching them async can be a solution. However, we can run into other problems.

1. Those values can be a lot. Waiting for all of them to be fetched beforehand may not be the best we can have.
2. Fetching them async but **partially** can be problematic. For example, if those values are items in a `UITableView`, and the cells are sized according to those items.
So, cells cannot appear before the items are ready. Or else we experience seeing cells growing and shrinking; which may not be an optimal experience.
So, blocking till the items are fetched, may be a better alternative.

## Why not pagination

This technique is not presented as a superior alternative (or even an equal alternative) to pagination.
Pagination deals with batching expensive data (from a databse, web service) that can take significant time to be fetched, and such fetching can even fail.
This technique deals with data that we know that can be fetched fast, and won't possibly fail while doing so.
