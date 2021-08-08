//
//  MqttDecodePuback.swift
//  CocoaMQTT
//
//  Created by liwei wang on 2021/8/3.
//

import Foundation


public class MqttDecodePubAck: NSObject {

    static let shared = MqttDecodePubAck()


    let totalCount = 0
    var dataIndex = 0
    var propertyLength: Int = 0

    public var reasonCode: CocoaMQTTPUBACKReasonCode?
    public var msgid: UInt16 = 0
    public var reasonString: String?
    public var userProperty: [String: String]?




    
    public func decodePubAck(fixedHeader: UInt8, pubAckData: [UInt8]){
        //msgid
        let msgidResult = integerCompute(data: pubAckData, formatType: formatInt.formatUint16.rawValue, offset: dataIndex)
        msgid = UInt16(msgidResult!.res)
        dataIndex = msgidResult!.newOffset

        // 3.4.2.1 PUBACK Reason Code

        // The Reason Code and Property Length can be omitted if the Reason Code is 0x00 (Success) and there are no Properties. In this case the PUBACK has a Remaining Length of 2.
        if dataIndex + 1 > pubAckData.count {
            return
        }

        guard let ack = CocoaMQTTPUBACKReasonCode(rawValue: pubAckData[dataIndex]) else {
            return
        }
        reasonCode = ack
        dataIndex += 1


        // 3.4.2.2 PUBACK Properties
        // 3.4.2.2.1 Property Length
        let propertyLengthVariableByteInteger = decodeVariableByteInteger(data: pubAckData, offset: dataIndex)
        propertyLength = propertyLengthVariableByteInteger.res
        dataIndex = propertyLengthVariableByteInteger.newOffset

        let occupyIndex = dataIndex

        while dataIndex < occupyIndex + (propertyLength ?? 0) {

            let resVariableByteInteger = decodeVariableByteInteger(data: pubAckData, offset: dataIndex)
            dataIndex = resVariableByteInteger.newOffset
            let propertyNameByte = resVariableByteInteger.res
            guard let propertyName = CocoaMQTTPropertyName(rawValue: UInt8(propertyNameByte)) else {
                break
            }

            switch propertyName.rawValue {
            // 3.4.2.2.2 Reason String
            case CocoaMQTTPropertyName.reasonString.rawValue:
                guard let result = unsignedByteToString(data: pubAckData, offset: dataIndex) else {
                    break
                }
                reasonString = result.resStr
                dataIndex = result.newOffset

            // 3.4.2.2.3 User Property
            case CocoaMQTTPropertyName.userProperty.rawValue:
                var key:String?
                var value:String?
                guard let keyRes = unsignedByteToString(data: pubAckData, offset: dataIndex) else {
                    break
                }
                key = keyRes.resStr
                dataIndex = keyRes.newOffset

                guard let valRes = unsignedByteToString(data: pubAckData, offset: dataIndex) else {
                    break
                }
                value = valRes.resStr
                dataIndex = valRes.newOffset

                userProperty![key!] = value


            default:
                return
            }

        }

    }
}