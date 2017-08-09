//
// ChatTableViewCell.swift
//
// Tigase iOS Messenger
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. Look for COPYING file in the top folder.
// If not, see http://www.gnu.org/licenses/.
//


import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet var avatarView: UIImageView?
    @IBOutlet var messageTextView: UILabel!
    @IBOutlet var messageFrameView: UIView!
    @IBOutlet var timestampView: UILabel!
    
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!;
    
    fileprivate static let todaysFormatter = ({()-> DateFormatter in
        var f = DateFormatter();
        f.dateStyle = .none;
        f.timeStyle = .short;
        return f;
    })();
    fileprivate static let defaultFormatter = ({()-> DateFormatter in
        var f = DateFormatter();
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "dd.MM, jj:mm", options: 0, locale: NSLocale.current);
        //        f.timeStyle = .NoStyle;
        return f;
    })();
    fileprivate static let fullFormatter = ({()-> DateFormatter in
        var f = DateFormatter();
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "dd.MM.yyyy, jj:mm", options: 0, locale: NSLocale.current);
        //        f.timeStyle = .NoStyle;
        return f;
    })();
    
    fileprivate func formatTimestamp(_ ts: Date) -> String {
        let flags: Set<Calendar.Component> = [.day, .year];
        let components = Calendar.current.dateComponents(flags, from: ts, to: Date());
        if (components.day! < 1) {
            return ChatTableViewCell.todaysFormatter.string(from: ts);
        }
        if (components.year! != 0) {
            return ChatTableViewCell.fullFormatter.string(from: ts);
        } else {
            return ChatTableViewCell.defaultFormatter.string(from: ts);
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        if messageFrameView != nil {
            //messageFrameView.backgroundColor = UIColor.li();
            messageFrameView.layer.masksToBounds = true;
            messageFrameView.layer.cornerRadius = 6;
        }
        if avatarView != nil {
            avatarView!.layer.masksToBounds = true;
            avatarView!.layer.cornerRadius = avatarView!.frame.height / 2;
        }
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureDidFire));
        messageTextView.addGestureRecognizer(tapGestureRecognizer);
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setTimestamp(_ ts: Date) {
        timestampView.text = formatTimestamp(ts);
    }

    func setMessageText(_ text: String?) {
        if text != nil {
            let attrText = NSMutableAttributedString(string: text!);
            
            if let detect = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue | NSTextCheckingResult.CheckingType.address.rawValue | NSTextCheckingResult.CheckingType.date.rawValue) {
                let matches = detect.matches(in: text!, options: .reportCompletion, range: NSMakeRange(0, text!.characters.count));
                for match in matches {
                    var url: URL? = nil;
                    if match.url != nil {
                        url = match.url;
                    }
                    if match.phoneNumber != nil {
                        url = URL(string: "tel:\(match.phoneNumber!.replacingOccurrences(of: " ", with: "-"))");
                    }
                    if match.addressComponents != nil {
                        let query = match.addressComponents!.values.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlHostAllowed);
                        if query != nil {
                            url = URL(string: "http://maps.apple.com/?q=\(query!)");
                        }
                    }
                    if match.date != nil {
                        url = URL(string: "calshow:\(match.date!.timeIntervalSinceReferenceDate)");
                    }
                    if url != nil {
                        attrText.setAttributes([NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue, NSLinkAttributeName: url!], range: match.range);
                    }
                }
            }
            self.messageTextView.attributedText = attrText;
        } else {
            self.messageTextView.text = text;
        }
    }
    
    func tapGestureDidFire(_ recognizer: UITapGestureRecognizer) {
        guard self.messageTextView.attributedText != nil else {
            return;
        }
        
        let point = recognizer.location(in: self.messageTextView);
        let layoutManager = NSLayoutManager();
        let textStorage = NSTextStorage(attributedString: self.messageTextView.attributedText!);
        textStorage.addLayoutManager(layoutManager);
        let textContainer = NSTextContainer(size: self.messageTextView.bounds.size);
        textContainer.lineFragmentPadding = 0;
        textContainer.lineBreakMode = self.messageTextView.lineBreakMode;
        layoutManager.addTextContainer(textContainer);
        let idx = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil);
        if let url = self.messageTextView.attributedText?.attribute(NSLinkAttributeName, at: idx, effectiveRange: nil) as? NSURL {
            UIApplication.shared.open(url as URL);
        }
    }
}
