# StooqAPI-for-Finance-Quote
A [Finance::Quote](https://github.com/finance-quote/finance-quote) module (Perl), which retrieves financial data from [Stooq.com](https://stooq.com) API (not website, like [my other module](https://github.com/Kaligula0/Stooq-for-Finance-Quote)). It exposes asset's: name, price, open, high, low, close/last, ask, bid, volume and date/isodate/time of retrieval.

It is highly helpful with assets that are not present in other APIs like e.g. Polish mutual funds, bonds etc..

# Installation
Download files `StooqAPI*.pm` and paste them into Finance::Quote directory (probably `<perl_dir>\site\lib\Finance\Quote`). Then add their filenames (without `.pm` extension) (preferably in alphabetical order) to the `@MODULES` variable in `Quote.pm` (`<perl_dir>\site\lib\Finance`).

# Use
Methods are named same as filenames they're in – but filenames use CamelCase, while methods use snake_case (for example `stooq_api_usd2pln` in `StooqAPIusd2pln.pm`).

# Why so many modules?
Stooq API provides financial data for various assets, which is nice, but it never tells the asset's currency. (And I think it isn't likely to change soon, as I asked them). That's why you need to choose proper method (module) in F::Q for each asset you look up. I also created an additional version of each module, that converts the price from mother currency to PLN.

# Unofficial
The module is unofficial.

# Authors
Me.

# License
GPL 2.0
