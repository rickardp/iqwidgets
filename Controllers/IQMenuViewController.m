//
//  IQDrilldownPanelViewController.h
//  IQWidgets for iOS
//
//  Copyright 2012 Rickard Petzäll, EvolvIQ
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "IQMenuViewController.h"

#pragma mark - Private implementation details

@class _IQMenuDataSource;
@interface IQMenuViewController () {
    BOOL hasNotifications;
    _IQMenuDataSource* dataSource;
    UITableView* tableView;
}
- (void) _itemAdded:(NSInteger)itemDisplayIndex inSection:(IQMenuSection*)section shouldAnimate:(BOOL)animate;
- (void) _itemRemoved:(NSInteger)itemDisplayIndex inSection:(IQMenuSection*)section shouldAnimate:(BOOL)animate;
- (void) _sectionAdded:(IQMenuSection*)section shouldAnimate:(BOOL)animate;
- (void) _sectionRemovedAtIndex:(NSInteger)sectionDisplayIndex shouldAnimate:(BOOL)animate;
- (void) _reloadWithAnimate:(BOOL)animate;
- (void) _sectionTextChanged:(IQMenuSection*)section;
- (void) _itemTextChanged:(IQMenuItem*)item;
- (NSInteger) _displayIndexForSection:(IQMenuSection*)section;
- (void) _updateTheme;
- (void) _checkThemeChange:(NSNotification*)notification;
@end

@interface _IQMenuDataSource : NSObject <UITableViewDataSource, UITableViewDelegate> {
    __weak IQMenuViewController* parent;
    NSMutableArray* sections;
}
- (id) initWithMenu:(IQMenuViewController*)menu;
- (NSMutableArray*) sections;
- (IQMenuSection*) sectionAtIndex:(NSInteger)index;
- (NSInteger) _displayIndexForSection:(IQMenuSection*)section;
- (IQMenuItem*) itemAtSection:(NSInteger)section index:(NSInteger)index;
@property (nonatomic, retain) UIFont* itemFont;
@property (nonatomic, retain) UIColor* itemTextColor;
@property (nonatomic, retain) UIColor* itemBackgroundColor;
@property (nonatomic) UITextAlignment itemTextAlign;
@end

@interface IQMenuSection () {
    __weak IQMenuViewController* parent;
    NSMutableArray* items;
}
- (void) _setParent:(IQMenuViewController*)menu;
- (BOOL) _displaying;
- (NSArray*) _items;
- (int) _displayIndexForItem:(IQMenuItem*)item;
@end

typedef void (^_IQActionBlock)();
@interface IQMenuItem () {
    _IQActionBlock action;
    __weak IQMenuSection* parent;
}

- (void) _setParent:(IQMenuSection*)section;
@end

#pragma mark - IQMenuViewController implementation

@implementation IQMenuViewController
@synthesize theme, themeClasses, themeUniqueIdentifier, tableView=tableView;

- (id) init
{
    self = [super init];
    if(self) {
        dataSource = [[_IQMenuDataSource alloc] initWithMenu:self];
    }
    return self;
}

- (void) dealloc
{
    if(hasNotifications) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kIQThemeNotificationThemeChanged object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kIQThemeNotificationDefaultThemeChanged object:nil];
    }
}

- (void) loadView
{
    if(!hasNotifications) {
        hasNotifications = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_checkThemeChange:) name:kIQThemeNotificationThemeChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_checkThemeChange:) name:kIQThemeNotificationDefaultThemeChanged object:nil];
    }
    IQTheme* thm = self.theme;
    if(!thm) thm = [IQTheme defaultTheme];
    UITableViewStyle style = [thm tableViewStyleFor:self];
    tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame style:style];
    tableView.dataSource = dataSource;
    tableView.delegate = dataSource;
    UIColor* bgcolor = [thm backgroundColorFor:self];
    if(bgcolor != nil) {
        if(style == UITableViewStyleGrouped) {
            tableView.backgroundView = [[UIView alloc] init];
            tableView.backgroundView.backgroundColor = bgcolor;
        } else {
            tableView.backgroundColor = bgcolor;
        }
    }
    NSObject<IQThemeable>* inheritSection = [IQTheme themeableForElement:@"section" ofParent:self defaultInherit:YES];
    NSObject<IQThemeable>* noinheritSection = [IQTheme themeableForElement:@"section" ofParent:self defaultInherit:NO];
    NSObject<IQThemeable>* inheritItem = [IQTheme themeableForElement:@"item" ofParent:inheritSection defaultInherit:YES];
    NSObject<IQThemeable>* noinheritItem = [IQTheme themeableForElement:@"item" ofParent:noinheritSection defaultInherit:NO];
    tableView.separatorColor = [thm borderColorFor:inheritItem];
    dataSource.itemFont = [thm fontFor:inheritItem];
    dataSource.itemTextColor = [thm colorFor:inheritItem];
    UITextAlignment aln = [thm textAlignmentFor:inheritItem];
    if(aln > 0) {
        dataSource.itemTextAlign = aln;
    } else {
        dataSource.itemTextAlign = UITextAlignmentLeft;
    }
    dataSource.itemBackgroundColor = [thm backgroundColorFor:(style == UITableViewStyleGrouped)?noinheritItem:inheritItem];
    self.view = tableView;
}

- (NSString*) themeElementName
{
    return @"menu";
}

- (void) setTheme:(id<IQThemeProvider>)thm
{
    self->theme = thm;
    [self _updateTheme];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) addSection:(IQMenuSection*)section animated:(BOOL)animated
{
    [section _setParent:self];
    [dataSource.sections addObject:section];
    [tableView reloadData]; // TODO
}

- (void) removeSection:(IQMenuSection*)section animated:(BOOL)animated
{
    [section _setParent:nil];
    NSInteger displayIndex = [dataSource _displayIndexForSection:section];
    if(displayIndex == NSNotFound) return;
    
    [dataSource.sections removeObject:section];
    
    [self _sectionRemovedAtIndex:displayIndex shouldAnimate:animated];
}

- (void) removeAllSections
{
    for(IQMenuSection* section in dataSource.sections) {
        [section _setParent:nil];
    }
    [dataSource.sections removeAllObjects];
    [tableView reloadData];
}

- (NSArray*) sections
{
    return dataSource.sections;
}

- (NSInteger) _displayIndexForSection:(IQMenuSection*)section
{
    return [dataSource _displayIndexForSection:section];
}

- (void) _itemAdded:(NSInteger)itemDisplayIndex inSection:(IQMenuSection*)section shouldAnimate:(BOOL)animate
{
    NSInteger sectionDisplayIndex = [dataSource _displayIndexForSection:section];
    if(sectionDisplayIndex == NSNotFound) {
        [NSException raise:@"SectionNotVisible" format:@"Section not visible in _itemAdded"];
    }
    [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:itemDisplayIndex inSection:sectionDisplayIndex]] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

- (void) _itemRemoved:(NSInteger)itemDisplayIndex inSection:(IQMenuSection*)section shouldAnimate:(BOOL)animate
{
    NSInteger sectionDisplayIndex = [dataSource _displayIndexForSection:section];
    if(sectionDisplayIndex == NSNotFound) {
        [NSException raise:@"SectionNotVisible" format:@"Section not visible in _itemRemoved"];
    }
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:itemDisplayIndex inSection:sectionDisplayIndex]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) _sectionAdded:(IQMenuSection*)section shouldAnimate:(BOOL)animate
{
    NSInteger displayIndex = [dataSource _displayIndexForSection:section];
    if(displayIndex == NSNotFound) {
        [NSException raise:@"SectionNotVisible" format:@"Section not visible in _sectionAdded"];
    }
    [tableView insertSections:[NSIndexSet indexSetWithIndex:displayIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) _sectionRemovedAtIndex:(NSInteger)sectionDisplayIndex shouldAnimate:(BOOL)animate
{
    [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionDisplayIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) _reloadWithAnimate:(BOOL)animate
{
    [tableView reloadData];
}

- (void) _sectionTextChanged:(IQMenuSection*)section
{
    [tableView reloadData];
}

- (void) _itemTextChanged:(IQMenuItem*)item
{
    [tableView reloadData];
}

- (IQMenuSection*) sectionAtIndex:(NSInteger)index
{
    return [dataSource.sections objectAtIndex:index];
}

- (NSInteger) count
{
    return dataSource.sections.count;
}

- (void) _updateTheme
{
    if(tableView) {
        UIView* superview = tableView.superview;
        CGRect frame = tableView.frame;
        tableView.dataSource = nil;
        tableView.delegate = nil;
        NSInteger idx = [tableView.superview.subviews indexOfObject:tableView];
        
        [tableView removeFromSuperview];
        tableView = nil;
        self.view = nil;
        [self loadView];
        [superview insertSubview:tableView atIndex:idx];
        tableView.frame = frame;
    }
}

- (void) _checkThemeChange:(NSNotification*)notification
{
    if(tableView) {
        if([notification.name isEqualToString:kIQThemeNotificationDefaultThemeChanged]) {
            if(theme == nil) {
                [self _updateTheme];
            }
        } else if([notification.name isEqualToString:kIQThemeNotificationThemeChanged]) {
            if((theme != nil && notification.object == theme) || (theme == nil && notification.object == [IQTheme defaultTheme])) {
                [self _updateTheme];
            }
        }
    }
}

@end

#pragma mark - IQMenuSection implementation

@implementation IQMenuSection
@synthesize title, footerText, hidden, hideIfEmpty, themeClasses, themeUniqueIdentifier;

+ (IQMenuSection*) sectionWithTitle:(NSString*)headerTitle
{
    IQMenuSection* section = [[IQMenuSection alloc] init];
    section.title = headerTitle;
    return section;
}

- (NSString*) themeElementName
{
    return @"section";
}

- (NSObject<IQThemeable>*) parentThemeable
{
    return parent;
}

- (void) setFooterText:(NSString*)text
{
    self->footerText = text;
    [parent _sectionTextChanged:self];
}

- (void) setTitle:(NSString*)text
{
    self->title = text;
    [parent _sectionTextChanged:self];
}

- (IQMenuViewController*) menuViewController
{
    return parent;
}

- (int) _displayIndexForItem:(IQMenuItem*)item
{
    NSInteger index = 0;
    for(IQMenuItem* i in items) {
        if(!i.hidden) {
            if(i == item) return index;
            index++;
        }
    }
    return NSNotFound;
}

- (void) addItem:(IQMenuItem*)item animated:(BOOL)animated
{
    if(items == nil) items = [NSMutableArray arrayWithCapacity:8];
    
    [item _setParent:self];
    [items addObject:item];
    
    NSInteger displayIndex = [self _displayIndexForItem:item];
    if(displayIndex != NSNotFound) { // If not hidden
        [parent _itemAdded:displayIndex inSection:self shouldAnimate:animated];
    }
    
}

- (void) removeItem:(IQMenuItem*)item animated:(BOOL)animated
{
    BOOL displaying = [self _displaying];
    NSInteger displayIndex = [self _displayIndexForItem:item];
    NSInteger sectionDisplayIndex = NSNotFound;
    if(displaying && displayIndex != NSNotFound) {
        sectionDisplayIndex = [parent _displayIndexForSection:self];
    }
    
    [item _setParent:nil];
    [items removeObject:item];
    
    if(displaying && displayIndex != NSNotFound) {
        if([self _displaying]) {
            [parent _itemRemoved:displayIndex inSection:self shouldAnimate:animated];
        } else {
            [parent _sectionRemovedAtIndex:sectionDisplayIndex shouldAnimate:animated];
        }
    }
    [items removeObject:item];
}

- (void) removeAllItemsAnimated:(BOOL)animated
{
    if(items.count == 0) return;
    
    BOOL displaying = [self _displaying];
    NSInteger sectionDisplayIndex = NSNotFound;
    if(displaying) {
        sectionDisplayIndex = [parent _displayIndexForSection:self];
    }
    
    for(IQMenuItem* item in items) {
        [item _setParent:nil];
    }
    [items removeAllObjects];
    
    if(displaying) {
        if([self _displaying]) {
            [parent _itemRemoved:-1 inSection:self shouldAnimate:animated];
        } else {
            [parent _sectionRemovedAtIndex:sectionDisplayIndex shouldAnimate:animated];
        }
    }
}

- (IQMenuSection*) itemAtIndex:(NSInteger)index
{
    return [items objectAtIndex:index];
}

- (NSInteger) count
{
    return items.count;
}

- (BOOL) _displaying
{
    if(hidden) return NO;
    if(hideIfEmpty) {
        for(IQMenuItem* item in items) {
            if(!item.hidden) return YES;
        }
        return NO;
    }
    return YES;
}

- (NSArray*) _items
{
    return items;
}

- (void) _setParent:(IQMenuViewController*)menu
{
    parent = menu;
}

- (void) setHidden:(BOOL)newHiddenState
{
    [self setHidden:newHiddenState animated:YES];
}

- (void) setHidden:(BOOL)newHiddenState animated:(BOOL)animated
{
    if(newHiddenState != self->hidden)
    {
        NSInteger sectionDisplayIndex = [parent _displayIndexForSection:self];
        self->hidden = newHiddenState;
        if(newHiddenState) {
            [parent _sectionRemovedAtIndex:sectionDisplayIndex shouldAnimate:animated];
        } else {
            [parent _sectionAdded:self shouldAnimate:animated];
        }
    }
}
- (void) setHideIfEmpty:(BOOL)newHideState
{
    if(newHideState != self->hideIfEmpty) {
        NSInteger sectionDisplayIndex = [parent _displayIndexForSection:self];
        self->hideIfEmpty = newHideState;
        if(self.count == 0) {
            if(newHideState) {
                [parent _sectionRemovedAtIndex:sectionDisplayIndex shouldAnimate:NO];
            } else {
                [parent _sectionAdded:self shouldAnimate:NO];
            }
        }
    }
}

@end

#pragma mark - IQMenuItem implementation

@implementation IQMenuItem
@synthesize title, hidden;

+ (IQMenuItem*) itemWithTitle:(NSString*)title action:(void (^)())action
{
    IQMenuItem* item = [[IQMenuItem alloc] init];
    item->action = action;
    item.title = title;
    return item;
}

- (IQMenuSection*) section
{
    return parent;
}

- (IQMenuViewController*) menuViewController
{
    return self.section.menuViewController;
}

- (void) setHidden:(BOOL)newHiddenState
{
    [self setHidden:newHiddenState animated:YES];
}

- (void) setHidden:(BOOL)newHiddenState animated:(BOOL)animated
{
    if(newHiddenState != self->hidden) {
        BOOL wasDisplaying = parent._displaying;
        NSInteger sectionDisplayIndex = [self.menuViewController _displayIndexForSection:parent];
        self->hidden = newHiddenState;
        BOOL isDisplaying = parent._displaying;
        if(wasDisplaying && isDisplaying) {
            int index = [parent._items indexOfObject:self];
            if(index == NSNotFound) [NSException raise:@"ItemNotFound" format:@"Item %@ not in parent section", self];
            if(!newHiddenState) {
                [self.menuViewController _itemAdded:index inSection:parent shouldAnimate:animated];
            } else {
                [self.menuViewController _itemRemoved:index inSection:parent shouldAnimate:animated];
            }
        } else if(wasDisplaying != isDisplaying) {
            if(wasDisplaying) {
                [self.menuViewController _sectionRemovedAtIndex:sectionDisplayIndex shouldAnimate:YES];
            } else {
                [self.menuViewController _sectionAdded:parent shouldAnimate:YES];
            }
        }
    }
}

- (void) itemActivated
{
    if(action != nil) action();
}

- (void) _setParent:(IQMenuSection*)section
{
    self->parent = section;
}

@end

@implementation _IQMenuDataSource
@synthesize itemFont, itemTextColor, itemBackgroundColor, itemTextAlign;

- (id) initWithMenu:(IQMenuViewController*)menu
{
    self = [super init];
    if(self) {
        self->parent = menu;
        self->sections = [[NSMutableArray alloc] initWithCapacity:8];
    }
    return self;
}

- (NSMutableArray*) sections
{
    return self->sections;
}

- (IQMenuSection*) sectionAtIndex:(NSInteger)index
{
    NSInteger count = 0;
    for(IQMenuSection* s in sections) {
        if(s._displaying) {
            if(count == index) return s;
            count++;
        }
    }
    [NSException raise:@"SectionIndexOutOfBounds" format:@"Section index %d out of bounds", index];
    return nil;
}

- (NSInteger) _displayIndexForSection:(IQMenuSection*)section
{
    NSInteger count = 0;
    for(IQMenuSection* s in sections) {
        if(s._displaying) {
            if(s == section) return count;
            count++;
        }
    }
    return NSNotFound;
}

- (IQMenuItem*) itemAtSection:(NSInteger)section index:(NSInteger)index
{
    IQMenuSection* s = [self sectionAtIndex:section];
    NSInteger count = 0;
    for(IQMenuItem* item in s._items) {
        if(!item.hidden) {
            if(count++ == index) return item;
        }
    }
    [NSException raise:@"ItemIndexOutOfBounds" format:@"Item index %d out of bounds", index];
    return nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    for(IQMenuSection* s in sections) {
        if(s._displaying) count++;
    }
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    IQMenuSection* s = [self sectionAtIndex:section];
    for(IQMenuItem* item in s._items) {
        if(!item.hidden) count++;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IQMenuItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    IQMenuItem* item = [self itemAtSection:indexPath.section index:indexPath.row];
    
    cell.textLabel.font = itemFont;
    cell.textLabel.text = item.title;
    cell.textLabel.textAlignment = itemTextAlign;
    if(itemBackgroundColor) {
        cell.backgroundColor = itemBackgroundColor;
    }
    if(itemTextColor) {
        cell.textLabel.textColor = itemTextColor;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self sectionAtIndex:section].title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self sectionAtIndex:section].footerText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)sectionIndex
{
    IQMenuSection* section = [self sectionAtIndex:sectionIndex];
    if(section.footerText.length == 0) {
        return 0;
    } else {
        return 20.0f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)sectionIndex
{
    IQMenuSection* section = [self sectionAtIndex:sectionIndex];
    if(section.footerText.length == 0) {
        return nil;
    }
    IQTheme* thm = parent.theme;
    if(!thm) thm = [IQTheme defaultTheme];
    
    UILabel* lbl = [[UILabel alloc] init];
    lbl.textAlignment = UITextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textColor = [UIColor darkGrayColor];
    lbl.shadowColor = [UIColor whiteColor];
    lbl.shadowOffset = CGSizeMake(0,1);
    lbl.font = [UIFont systemFontOfSize:15];
    if([thm applyToView:lbl for:section flags:IQThemeViewApplyAllStyles]) {
        lbl.text = section.footerText;
        return lbl;
    }
    
    return nil;
}
/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IQMenuItem* item = [self itemAtSection:indexPath.section index:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [item itemActivated];
}


@end