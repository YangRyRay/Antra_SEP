import json

with open('movie.json', 'r', encoding='utf8') as f:
    movies = [line for line in json.load(f)['movie']]
    splits = 8
    per_split = len(movies) // splits

    for i in range(splits):
        if i == splits-1:
            json.dump(movies[per_split * i:], open("movie_split_" + str(i + 1) + ".json", 'w'), indent=True)
        else:
            json.dump(movies[per_split * i: per_split * (i + 1)], open("movie_split" + str(i + 1) + ".json", 'w'),
                      indent=True)
