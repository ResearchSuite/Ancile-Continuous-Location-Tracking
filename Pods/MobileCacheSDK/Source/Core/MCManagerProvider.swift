//
//  MCManagerProvider.swift
//  MCSDK
//
//  Created by James Kizer on 1/17/2018.
//

public protocol MCManagerProvider {
    func getManager() -> MCManager?
}
