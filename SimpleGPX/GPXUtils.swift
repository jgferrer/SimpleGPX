//
//  GPXUtils.swift
//  SimpleGPX
//
//  Created by Jose Gabriel Ferrer on 20/04/2019.
//  Copyright © 2019 Jose Gabriel Ferrer. All rights reserved.
//

import Foundation
import MapKit
import CoreGPX


class GPXUtils {

    open class var shared: GPXUtils {
        struct Static {
            static let instance: GPXUtils = GPXUtils()
        }
        return Static.instance
    }
    
    open func getCoordinateArray(withURL url: String) -> [CLLocationCoordinate2D] {
        guard let url: URL = URL(string: url) else { return [] }
        guard let gpx = GPXParser(withURL: url)?.parsedData() else { return [] }
        let tracks = gpx.tracks
        return self.coordinateArray(withTracks: tracks)
    }
    
    open func getCoordinateArray(withPath path: String) -> [CLLocationCoordinate2D] {
        guard let gpx = GPXParser(withPath: path)?.parsedData() else { return [] }
        let tracks = gpx.tracks
        return self.coordinateArray(withTracks: tracks)
    }
    
    open func gettCoordinateArray(withFileNamed file: String) -> [CLLocationCoordinate2D] {
        guard let inputPath = Bundle.main.path(forResource: file, ofType: "gpx") else { return [] }
        var text: String = ""
        do {
            text = try String(contentsOfFile: inputPath)
        }
        catch(_){print("error")}
        guard let gpx = GPXParser(withRawString: text)?.parsedData() else { return [] }
        let tracks = gpx.tracks
        return self.coordinateArray(withTracks: tracks)
    }
    
    func coordinateArray(withTracks tracks: [GPXTrack]) -> [CLLocationCoordinate2D] {
        var coordinateArray = [CLLocationCoordinate2D]()
        guard tracks.count > 0 else { return [] }
        for track in tracks {
            for tracksegment in track.tracksegments {
                for trackpoint in tracksegment.trackpoints {
                    if let latitude = trackpoint.latitude, let longitude = trackpoint.longitude {
                        coordinateArray.append(CLLocationCoordinate2DMake(latitude, longitude))
                    }
                }
            }
        }
        return coordinateArray
    }
}
