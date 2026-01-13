#!/usr/bin/python3
'''
doujinstyle-genre-tagger
------------------------
a simple python3 script to
scrape doujinstyle.com
and tag your tracks

this assumes your album tag
is 1:1 with the doujinstyle
listing
'''

import sys, os, threading, time
import taglib # req pytaglib
import requests as req # req requests
from alive_progress import alive_bar # req alive-progress

HELPTEXT="""\
Doujinstyle tagger - a program to tag your music library based off albums' doujinstyle webpages

usage:
    main.py -d <directory> [options]

flags:
    -h, --help       show this help text

variables:
    -s, --safe-mode  do not perform any file writes, a dry run (default: false)
    -d, --directory  set your music library directory (default: prompt)
    -j, --jobs       (unsafe as of now) change maximum number of threads (default: 1)

dependencies:
    [pip]
    pytaglib
    alive-progress
    requests

    [system]
    taglib

contact:
    don't.
"""

## SUPPORTED FILETYPES ##
allowed_types = (
        '.mp3',
        '.ogg',
        '.flac',
#        '.wav', # wav doesnt have genre tags i think
)

## PARSE ARGUMENTS ##
def parse_args():
        # Default options
        opts = {
                'dry' : False,
                'dir' : None,
                'verbose' : False,
                'jobs' : 1,
        }

        skip = 1
        # iterate over all args
        for i, arg in enumerate(sys.argv):
                if skip > 0:
                        skip = skip - 1
                elif arg[:1] == '-':
                        # arg is switch
                        match arg:
                                case '-h' | '--help':
                                        print(HELPTEXT)
                                        sys.exit(0)
                                case '-s' | '--safe-mode':
                                        opts['dry'] = True
                                case '-d' | '--directory':
                                        skip = 1 # next arg is directory
                                        opts['dir'] = sys.argv[i + 1]
                                case '-v' | '--verbose':
                                        opts['verbose'] = True
                                case '-j' | '--jobs':
                                        skip = 1 # next arg is n of jobs
                                        if int(sys.argv[i+1]) > 1 and input('are you sure you want >1 jobs? it might be unsafe because im a bad programmer. it also provides like no benefit.') == 'y':
                                                opts['jobs'] = int(sys.argv[i + 1])
                                case _:
                                        print('Unknown argument: ' + arg)
                                        sys.exit(1)
                else:
                        print('arg: ' + arg)
                        # arg is verb
                        print('unknown argument: ' + arg)
                        sys.exit(1)

        if opts['verbose']:
                print('options:' + str(opts))

        return opts

opts = parse_args()

## GET LIST OF ALL FILES ##
def walk_directory(input_dir):
        with alive_bar(0) as bar:
                track_files = walk_directory_helper(input_dir, bar)
                bar.text('')
                return track_files

def walk_directory_helper(input_dir, bar):
        bar.text('scanning ' + input_dir)

        if not os.path.exists(input_dir):
                print('directory does not exist:' + input_dir)
                sys.exit(1)

        # scan directory
        track_files = []
        for item in os.scandir(input_dir):
                if item.is_file():
                        _, file_extension = os.path.splitext(item)
                        if file_extension != '' and any(file_extension in t for t in allowed_types):
                                track_files.append( os.path.join(input_dir, item) )
                                bar()
                elif item.is_dir():
                        for file in walk_directory_helper( os.path.join(input_dir, item, ""), bar ): # recursive
                                track_files.append( file )

        return track_files

## GET TAGS OF FILES ##
def get_tags(tracks, tag_list, bar):
        tags = {}
        for track in tracks:
                bar.text('seading tags of ' + track)
                try:
                        tag_list[track] = taglib.File(track).tags
                except:
                        print('error in reading tags for ' + track)
                bar()
        return tags

## THREADED TAG GETTING ##
def get_tags_threaded(tracks):
        length = len(tracks)
        num_threads = opts['jobs']
        threads = []

        with alive_bar(length) as bar:
                if opts['verbose']:
                        bar.text('awaiting ' + str(num_threads) + ' threads for tag processing')

                # create workers
                tag_list = {}
                min = 1
                for i in range(1, num_threads + 1):
                        max = int( (length / num_threads) * i )
                        if opts['verbose']: # (hack) avoid mess with the statusbar using \n\r
                                print("\n\rcreating worker #" + str(i) + ": items " + str(min) + " to " + str(max), end='')
                        thread = threading.Thread(
                                target=get_tags,
                                args=(tracks[min-1:max], tag_list, bar)
                        )
                        threads.append(thread)
                        min = max + 1

                # start workers
                for thread in threads:
                        thread.start()

                # await workers
                for thread in threads:
                        thread.join()
                        num_threads -= 1

                return tag_list

## GET TAGS FROM DOUJINSTYLE ##
'''
# turns out this method isnt even needed cause the tags are in full in the search html. end me.
def get_tags_from_id(id_num):
        print('getting tags for id ' + str(id_num))
        tags = None
        text = req.get("https://doujinstyle.com/?p=page&type=1&id=" + str(id_num)).text
        tmp = text.split("<span class=\"pageSpan1\">Tags:</span>")
        if len(tmp) <= 1:
                print('no tags found for id ' + str(id_num))
                if input('manually specify tags? (y/n)') == 'y':
                        tags = input('enter tags (comma separated, spaces between entries): ')
        else:
                tmp = tmp[1]
                print(tmp[0:500])

        return tags
'''
def get_tags_from_name(album):
        print("searching for " + album)
        text = req.get("https://doujinstyle.com/?p=search&type=blanket&result=" + album).text
        albums = {}
        tmp = text.split('gridPresent')
        tmp[0] == None
        for item in tmp:
                if item == None or item[0] == '<' or int(item[0]) > int('9') or int(item[0]) < int('0'):
                        pass
                else:
                        # cull extra text to prevent search errors, large padding to be safe tho.
                        item = item[0:min(2700, len(item))]

                        # GET ID NUM
                        start_index = item.find("<div class=\"gridDetails\">")
                        if start_index == -1:
                                continue

                        start_index = start_index + 55
                        end_index = item.find("\">", start_index)
                        id_num = item[start_index:end_index]

                        # GET TITLE
                        start_index = item.find("title=", end_index)
                        if start_index == -1:
                                continue

                        start_index = start_index + 7
                        end_index = item.find("\">", start_index)
                        title = item[start_index:end_index]

                        # GET TAGS
                        tags = ''
                        start_index = item.find("gridTinyTag", end_index)
                        end_index = start_index
                        max_index = item.find("</span>", start_index)
                        while(start_index != -1 and end_index != -1):
                                start_index = item.find("result=", end_index)
                                if start_index == -1:
                                        break
                                end_index = item.find("\"", start_index)
                                tags = tags + ', ' + item[start_index+7:end_index]

                        if tags != '':
                                tags = tags[2:]
                                tags = tags.replace("&#45;", "-") # annoying web stuff idk

                        albums[title] = {
                                'id' : id_num,
                                'tags' : tags,
                        }

        if len(albums) < 1:
                print("no matches found for " + album)
                albums = None
        elif len(albums) == 1:
                for entry in albums:
                        print("match found for " + album + " as " + entry + " | id: " + albums[entry]['id'] + " | tags: " + str(albums[entry]['tags']))
                        albums = albums[entry]
        else:
                print("multiple matches found for " + album)
                count = 0
                for entry in albums:
                        print(str(count) + ": " + entry + " | id: " + albums[entry]['id'] + " | tags: " + str(albums[entry]['tags']))
                        count = count + 1
                while(True):
                        selection = input("select an option above [0-" + str(len(albums)-1) + "] ")
                        if selection == '' or int(selection) >= len(albums) or int(selection) < 0:
                                print("please try again")
                        else:
                                albums = albums[list(albums)[int(selection)]]
                                break

        if albums == None or albums['tags'] == 'None':
                print('no tags found!')
                if input('manually specify tags? (y/n) ') == 'y':
                        return input('enter tags (comma separated, spaces between entries): ')
                else:
                        return None
        return albums['tags']

## MAIN PROGRAM ##
def main():
        if opts['dry'] == True:
                print('RUNNING IN DRY MODE: NO FILES WILL BE MODIFIED!!')
        else:
                print('RUNNING FOR REAL: FILES WILL BE MODIFIED!!')

        # directory scanning
        if opts['dir'] == None:
                opts['dir'] = input('input a directory to scan:')
        tracks = walk_directory( opts['dir'] )

        # threaded tagging operations
        tracks = get_tags_threaded(tracks)

        # sort into albums
        albums = {}
        for track in tracks:
                album = tracks[track].get('ALBUM')
                if album == None or len(album) == 0:
                        pass
                else:
                        album = album[0];
                        if albums.get(album) == None:
                                albums[album] = []
                        albums[album].append(track)
        count = 0
        for album in albums:
                count = 1 + count
        print(str(count) + " alubumsdfsdfsd")
        # get tags per album from doujinstyle
        for album in albums:
                print("----------")
                tags = get_tags_from_name(album)
                if tags == None:
                        continue
                if input('would you like to apply \"' + str(tags) + '\" to ' + album + '? (y/n) ') == 'y':
                        for track in albums[album]:
                                try:
                                        if opts['verbose']:
                                                print('modifying ' + track)
                                        if opts['dry'] == False:
                                                song = taglib.File(track)
                                                song.tags["GENRE"] = [tags]
                                                song.save()
                                except Exception as e:
                                        print('error in changing tags for ' + track)
                                        print("An exception of type {0} occurred. Arguments:\n{1!r}".format(type(e).__name__, e.args))
        #return tags


## RUN THE PROGRAM ##
main()
