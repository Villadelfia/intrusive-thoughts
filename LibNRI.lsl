// LibNRI version 1.0.0 - 2023-07-06.
//
// LibNRI is licensed under the MIT license and copyright Hana Nova (Randy
// Thiemann) <randy.thiemann@gmail.com>.
//
// This is a library of useful LSL functions that are not by default included
// in the LL standard library. All functions in this file are prepended with
// nri and assuming the script preprocessor in Firestorm is enabled with all
// options enabled, you can safely include it in any of your scripts using
// the #include <...> directive.
//
// Everything is documented using the JavaDoc format.


///////////////////////////////////////////////////////////////////////////////
// Checking for contents.
//
// These functions check if strings/lists contain certain strings/lists in
// specific positions such as the beginning or the end, or in general.

/**
 * Returns whether or not haystack starts with needle.
 *
 * @param  haystack  The string to check in.
 * @param  needle    The prefix to check for.
 * @return           TRUE if haystack starts with needle. FALSE otherwise.
 **/
integer nriStringStartsWith(string haystack, string needle) {
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

/**
 * Returns whether or not haystack contains needle.
 *
 * @param  haystack  The string to check in.
 * @param  needle    The contents to check for.
 * @return           TRUE if haystack contains needle. FALSE otherwise.
 **/
integer nriStringContains(string haystack, string needle) {
    return 0 <= llSubStringIndex(haystack, needle);
}

/**
 * Returns whether or not haystack ends with needle.
 *
 * @param  haystack  The string to check in.
 * @param  needle    The contents to check for.
 * @return           TRUE if haystack ends with needle. FALSE otherwise.
 **/
integer nriStringEndsWith(string haystack, string needle) {
    return llDeleteSubString(haystack, 0x8000000F, ~llStringLength(needle)) == needle;
}

/**
 * Returns whether or not haystack starts with needle. Note that (key)"abc" != (string)"abc".
 *
 * @param  haystack  The list to check in.
 * @param  needle    The prefix to check for.
 * @return           TRUE if haystack starts with needle. FALSE otherwise.
 **/
integer nriListStartsWith(list haystack, list needle) {
    return llListFindList(haystack, needle) == 0;
}

/**
 * Returns whether or not haystack contains needle. Note that (key)"abc" != (string)"abc".
 *
 * @param  haystack  The list to check in.
 * @param  needle    The contents to check for.
 * @return           TRUE if haystack contains needle. FALSE otherwise.
 **/
integer nriListContains(list haystack, list needle) {
    return 0 <= llListFindList(haystack, needle);
}

/**
 * Returns whether or not haystack ends with needle. Note that (key)"abc" != (string)"abc".
 *
 * @param  haystack  The list to check in.
 * @param  needle    The contents to check for.
 * @return           TRUE if haystack ends with needle. FALSE otherwise.
 **/
integer nriListEndsWith(list haystack, list needle) {
    return llListFindList(haystack, needle) == llGetListLength(haystack) - llGetListLength(needle);
}


///////////////////////////////////////////////////////////////////////////////
// String manipulation and information functions.

/**
 * A convenience wrapper for the most common case of llStringTrim with full
 * whitespace trimming. (Both front and back.)
 *
 * @param  str  The string to trim.
 * @return      The trimmed string.
 **/
string nriTrim(string str) {
    return llStringTrim(str, STRING_TRIM);
}

/**
 * Removes a prefix from a string, and returns the resulting string with
 * whitespace trimmed off.
 *
 * Note that you should make sure that str actually starts with prefix.
 *
 * @param  str     The string to trim the prefix from.
 * @param  prefix  The prefix to trim.
 * @return         The input string with the character count of prefix removed.
 *                 and trimmed of remaining surrounding whitespace.
 **/
string nriRemovePrefix(string str, string prefix) {
    return nriTrim(llDeleteSubString(str, 0, llStringLength(prefix)-1));
}

/**
 * Counts the amount of bytes in str. Useful for chat commands which are
 * limited to 1024 bytes.
 *
 * @param  str  The string to count the bytes of.
 * @return      The amount of bytes in str.
 **/
integer nriGetStringBytes(string str) {
    return (llStringLength((string)llParseString2List(llStringToBase64(str), ["="], [])) * 3) >> 2;
}

/**
 * Gets the arguments passed to a command by trimming off the command from the
 * start.
 *
 * A case insensitive comparison is done between the start of str and command.
 * If they match, command will be trimmed from the front of str and the
 * remainder is trimmed of whitespace and returned. If they do not match,
 * sentinel is returned.
 *
 * @param  str       The full string to parse.
 * @param  command   The command to check for.
 * @param  sentinel  The value to return if str doesn't start with command.
 * @return           The parsed argument or the sentinel value if str is
 *                   invalid.
 **/
string nriParseCommand(string str, string command, string sentinel) {
    str = nriTrim(str);
    command = nriTrim(command);
    if(!nriStringStartsWith(llToLower(str), llToLower(command))) return sentinel;
    return nriRemovePrefix(str, command);
}

/**
 * Similar to nriParseCommand, but splits the value by the given delimiter.
 *
 * @param  str        The full string to parse.
 * @param  command    The command to check for.
 * @param  delimiter  The delimiter to split by.
 * @param  sentinel   The value to return if str doesn't start with command.
 * @return            The parsed arguments or the sentinel value if str is
 *                    invalid.
 * @see               nriParseCommand.
 **/
list nriParseDelimitedCommand(string str, string command, string delimiter, list sentinel) {
    str = nriTrim(str);
    command = nriTrim(command);
    if(!nriStringStartsWith(llToLower(str), llToLower(command))) return sentinel;
    return llParseStringKeepNulls(nriRemovePrefix(str, command), [delimiter], []);
}
