import csv
import codecs
import cStringIO
import unicodedata
import re

# words_n_spaces_pattern = re.compile(ur'[^\w\s]+', re.UNICODE)
# control_pattern = re.compile(ur'[\c]+', re.UNICODE)
code_pattern = re.compile(ur'```(.)+```', re.UNICODE)
# non_english = re.compile(ur'[^\x00-\x7F]+', re.UNICODE)
# check https://regex101.com/r/qU7nL1/1 for a test case :)
latin_letters = {}
NaChar = u'N/A'
skipped = 0
body_unprocessed = 0
# name_unprocessed = 0


def is_latin(uchr):
    try:
        return latin_letters[uchr]
    except KeyError:
        return latin_letters.setdefault(uchr, 'LATIN' in unicodedata.name(uchr))


def only_roman_chars(unistr):
    return all(is_latin(uchr) for uchr in unistr if uchr.isalpha())  # isalpha suggested by John Machin


def remove_control_characters(s):
    return "".join(ch for ch in s if unicodedata.category(ch)[0] != "C")


def gracefully_degrade_to_ascii(text):
    return unicodedata.normalize('NFKD', text).encode('ascii', 'ignore')


class WriterDialect(csv.Dialect):
    strict = True
    skipinitialspace = True
    quoting = csv.QUOTE_ALL
    delimiter = ';'
    escapechar = '\\'
    quotechar = '"'
    lineterminator = '\n'


class UTF8Recoder:
    """
    Iterator that reads an encoded stream and re-encodes the input to UTF-8
    """
    def __init__(self, f, encoding):
        self.reader = codecs.getreader(encoding)(f)

    def __iter__(self):
        return self

    def next(self):
        return self.reader.next().encode("utf-8")


class UnicodeReader:
    """
    A CSV reader which will iterate over lines in the CSV file "f",
    which is encoded in the given encoding.
    """

    def __init__(self, f, dialect=csv.excel, encoding="utf-8", **kwds):
        f = UTF8Recoder(f, encoding)
        self.reader = csv.reader(f, dialect=dialect, **kwds)

    def next(self):
        row = self.reader.next()
        return [unicode(s, "utf-8") for s in row]

    def __iter__(self):
        return self


class UnicodeWriter:
    """
    A CSV writer which will write rows to CSV file "f",
    which is encoded in the given encoding.
    """

    def __init__(self, f, dialect=WriterDialect, encoding="utf-8", **kwds):
        # Redirect output to a queue
        self.queue = cStringIO.StringIO()
        self.writer = csv.writer(self.queue, dialect=dialect, **kwds)
        self.stream = f
        self.encoder = codecs.getincrementalencoder(encoding)()

    def writerow(self, row):
        self.writer.writerow([s.encode("utf-8") for s in row])
        # Fetch UTF-8 output from the queue ...
        data = self.queue.getvalue()
        data = data.decode("utf-8")
        # ... and reencode it into the target encoding
        data = self.encoder.encode(data)
        # write to the target stream
        self.stream.write(data)
        # empty queue
        self.queue.truncate(0)

    def writerows(self, rows):
        for row in rows:
            self.writerow(row)


with open('discussions_clean.csv', 'wb') as fout:
    with open('discussions.csv', 'rb') as fin:
        reader = UnicodeReader(fin, quoting=csv.QUOTE_MINIMAL, delimiter=';', strict=True, escapechar='\\')
        writer = UnicodeWriter(fout, quoting=csv.QUOTE_ALL, delimiter=';',
                               strict=True, escapechar='\\', encoding="utf-8")

        for line in reader:

            # REGEX matching for:
            # nothing less than words and a space in 'name' ("name and surname")
            # line[7] = words_n_spaces_pattern.sub('', line[7])
            # removing control chars by regex matching (2nd stage in line #117 below)
            # line[2] = control_pattern.sub('', line[2])
            # replacing markdown code blocks with a simple mark
            line[2] = code_pattern.sub('[code]', line[2])

            # removing obvious messy escape characters
            line[2] = line[2].replace("\"", '').replace("\\", "").replace(';', '')
            # line[7] = line[7].replace("\"", '').replace("\\", "").replace(';', '')

            # removing unichar control chars from 'body' and 'name'
            line[2] = remove_control_characters(line[2])
            # line[7] = remove_control_characters(line[7])

            # line[2] = control_pattern.sub('[non-english]', line[2])
            # it doesn't work
            # print type(line[2])
            try:
                line[2] = gracefully_degrade_to_ascii(line[2])
            except:
                print 'Nothing to slugify: ' + str(line[2])
                print 'Type of body ' + str(type(line[2]))
                body_unprocessed += 1

            writer.writerow(line)

print "Done!"
print 'skipped: ' + str(skipped)
print 'unslugified body: ' + str(body_unprocessed)
# print 'unslugified name: ' + str(name_unprocessed)
