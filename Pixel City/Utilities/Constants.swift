//
//  Constants.swift
//  Pixel City
//
//  Created by Hannie Kim on 11/22/18.
//  Copyright © 2018 Hannie Kim. All rights reserved.
//

import Foundation

let API_KEY = "e9087c85d28f9a8572f03ad9272e744a"

// return the API url
func flickrURL(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
