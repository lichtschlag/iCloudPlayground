//
//  iCPDocumentsController.h
//  iCloudPlayground
//
//  Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 13/Nov/11.
//  Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.
//

#import <UIKit/UIKit.h>

// ===============================================================================================================
@interface iCPDocumentsController : UITableViewController
// ===============================================================================================================

@property (weak, nonatomic) IBOutlet UILabel    *syncLabel;
@property (retain) NSMetadataQuery *query;
@property (retain) NSMutableArray *fileList;
@property (retain) NSMutableArray *previousQueryResults;

- (IBAction) addDocument:(id)sender;
- (void) removeDocument:(id)sender atIndex:(NSInteger)index;

@end
