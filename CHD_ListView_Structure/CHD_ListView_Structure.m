//
//  UITableView+Structure.m
//
//
//  Created by chd on 2017/8/24.
//  Copyright © 2017年 chd. All rights reserved.
//

#import "CHD_ListView_Structure.h"
#import <objc/runtime.h>


//Switch
@interface CHD_SwitchView : UIButton

@end

//HookHelper
@interface CHD_HookHelper : NSObject
@property (nonatomic, retain) NSMapTable *weakListViewDic;
+ (instancetype)shareInstance;
- (void)hookSelectors:(NSArray *)selArr orginalObj:(id)oriObj swizzedObj:(id)newObj;
- (void)revertHooks;
@end


//MustrHelper
@interface CHD_MustrHelper : NSObject
@end


//Hover
@interface CHD_HoverLabel : UILabel
@end

@interface UIView (CHD_HoverView)
@end



//UITableView
@interface UITableView (CHD_Structure)
@end


//UICollectionView
@interface UICollectionView (CHD_Structure)

@end






#define chd_table_head_view_color [UIColor magentaColor]
#define chd_table_cell_color [UIColor redColor]
#define chd_table_header_color [UIColor blueColor]
#define chd_table_footer_color [UIColor greenColor]
#define chd_text_bg_alpha 0.7
#define chd_table_text_color [UIColor whiteColor]
#define chd_table_footer_view_color [UIColor blackColor]


#define chd_collection_cell_color [UIColor orangeColor]
#define chd_collection_header_color [UIColor purpleColor]
#define chd_collection_footer_color [UIColor cyanColor]
#define chd_collection_bg_alpha 1
#define chd_collection_text_color [UIColor whiteColor]


static NSString *const CHD_MapTable_Obj = @"CHD_MapTable_Obj";


void __CHD_Instance_Transition_Swizzle(Class originalClass,SEL originalSelector, Class swizzledClass, SEL swizzledSelector){
#ifdef DEBUG
    //实质上并不是交换两个类的方法，而是先对originalClass对象增加swizzledSelector方法，然后与自己的originalSelector交换。swizzledClass仅作为 要交换方法的提供者。
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    
    if (!originalMethod) {
        //如果原对象原方法未实现，查看交换类是否帮其实现了原类方法
        Method tempM = class_getInstanceMethod(swizzledClass, originalSelector);
        if (tempM) {
            //给原对象增加原方法
            class_addMethod(originalClass, originalSelector, method_getImplementation(tempM), method_getTypeEncoding(tempM));
            //更新原对象实现
            originalMethod = class_getInstanceMethod(originalClass, originalSelector);
        }
    }
    
    if (!originalMethod || !swizzledMethod) {
        return;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    //给原对象增加swizzledSelector方法,实现为originalIMP
    class_replaceMethod(originalClass,swizzledSelector,originalIMP,originalType);
    //替换originalSelector的实现为swizzledIMP
    class_replaceMethod(originalClass,originalSelector,swizzledIMP,swizzledType);
#endif
    
}

@implementation CHD_SwitchView
- (instancetype)initWithFrame:(CGRect)frame
{
    if ([super initWithFrame:frame]) {
        UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handelPan:)];
        [self addGestureRecognizer:pan];
        
        self.alpha = 1;
    }
    return self;
}
- (void)handelPan:(UIPanGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.3 animations:^{
            gestureRecognizer.view.alpha = 1;
        }];
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:1 animations:^{
                gestureRecognizer.view.alpha = 0.5;
            }];
        });
    }
    CGPoint center = [gestureRecognizer locationInView:self.superview];
    
    CGFloat minX = CGRectGetWidth(self.frame)/2.0;
    CGFloat maxX = [UIScreen mainScreen].bounds.size.width - minX;
    CGFloat minY = CGRectGetHeight(self.frame)/2.0;
    CGFloat maxY = [UIScreen mainScreen].bounds.size.height - minY;
    
    if (center.x<minX) {
        center = CGPointMake(minX, center.y);
    }
    if (center.y<minY) {
        center = CGPointMake(center.x, minY);
    }
    if (center.x>maxX) {
        center = CGPointMake(maxX, center.y);
    }
    if (center.y>maxY) {
        center = CGPointMake(center.x, maxY);
    }
    
    self.center = center;
}


@end



#pragma mark - CHD_ListView_Structure
@implementation CHD_ListView_Structure

+(void)openStructureShow_TableV:(BOOL)isOpenT collectionV:(BOOL)isOpenC
{
#ifdef DEBUG
    
    static BOOL isCalled = NO;
    if (isCalled) {
        return;
    }
    isCalled = YES;
    
    if (isOpenT) {
        [CHD_ListView_Structure hookTable];
    }
    if (isOpenC) {
        [CHD_ListView_Structure hookCollection];
    }
    
    if (isOpenT||isOpenT) {
        [CHD_ListView_Structure addToggleView];
    }
    
#endif
}
+ (void)addToggleView
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        CGFloat btnW = 50.0f;
        CHD_SwitchView *btn = [[CHD_SwitchView alloc] initWithFrame:CGRectMake(0, 50, btnW, btnW)];
        [btn setTitle:@"Toggle" forState:UIControlStateNormal];
        btn.layer.cornerRadius = btnW/2.0f;
        btn.backgroundColor = [UIColor orangeColor];
        btn.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture)];
        [btn addGestureRecognizer:tap];
        [window addSubview:btn];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [window bringSubviewToFront:btn];
        });
    });
}
+ (void)hookTable
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    __CHD_Instance_Transition_Swizzle([UITableView class], @selector(setDelegate:), [UITableView class],@selector(CHD_setDelegate:));
    __CHD_Instance_Transition_Swizzle([UITableView class], @selector(setDataSource:), [UITableView class],@selector(CHD_setDataSource:));
    NSArray *selArr = @[@"setTableFooterView:",@"setTableHeaderView:"];
    [[CHD_HookHelper shareInstance] hookSelectors:selArr orginalObj:[UITableView new] swizzedObj:[UITableView new]];
#pragma clang diagnostic pop
    
}
+ (void)hookCollection
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    __CHD_Instance_Transition_Swizzle([UICollectionView class], @selector(setDelegate:), [UICollectionView class], @selector(CHD_setDelegate:));
    __CHD_Instance_Transition_Swizzle([UICollectionView class], @selector(setDataSource:), [UICollectionView class], @selector(CHD_setDataSource:));
#pragma clang diagnostic pop
}

+ (void)tapGesture
{
    [[CHD_HookHelper shareInstance] revertHooks];
}

@end


#pragma mark - CHD_HookHelper
@implementation CHD_HookHelper
{
    NSMutableDictionary *swizzedData;
}
+ (instancetype)shareInstance
{
    static CHD_HookHelper *helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[self alloc] init];
    });
    return helper;
}

- (void)revertHooks
{
    for (NSString *info in [swizzedData allKeys]) {
        //类名中或方法名中不要包含_chd_hook_
        NSArray *temp = [info componentsSeparatedByString:@"_chd_hook_"];
        if (temp.count == 2) {
            Class hookClass = NSClassFromString(temp[0]);
            SEL orgSel = NSSelectorFromString(temp[1]);
            SEL swizeeSel = NSSelectorFromString([@"CHD_" stringByAppendingString:temp[1]]);
            __CHD_Instance_Transition_Swizzle(hookClass, orgSel, hookClass, swizeeSel);
        }
    }
    [self resetCHD_HoverView];
}

- (instancetype)init
{
    if ([super init]) {
        swizzedData = @{}.mutableCopy;
        self.weakListViewDic = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsCopyIn];
    }
    return self;
}


- (BOOL)chenckIsSwizzedOrgObj:(id)oriObj sel:(NSString*)sel
{
    if (!oriObj ||!sel) {
        return YES;
    }
    BOOL isFatherChanged = NO;//查找是否有父类或同类已经交换过
    for (NSString *keys in [swizzedData allKeys]) {
        NSString *saveClass = [[keys componentsSeparatedByString:@"_chd_hook_"] firstObject];
        if ([oriObj isKindOfClass:NSClassFromString(saveClass)] && [swizzedData[[self getUniqueStr:saveClass sel:sel]] boolValue]) {
            isFatherChanged = YES;
            break;
        }
    }
    if (isFatherChanged) {
        return isFatherChanged;
    }
    
    return [swizzedData[[self getUniqueStr:NSStringFromClass([oriObj class]) sel:sel]] boolValue];
}
- (void)hookSelectors:(NSArray *)selArr orginalObj:(id)oriObj swizzedObj:(id)newObj
{
    
    for (NSString *selStr in selArr) {
        SEL sel  = NSSelectorFromString(selStr);
        SEL newSel = NSSelectorFromString([@"CHD_" stringByAppendingString:selStr]);
        if (![self chenckIsSwizzedOrgObj:oriObj sel:selStr]) {
            __CHD_Instance_Transition_Swizzle([oriObj class], sel, [newObj class], newSel);
            swizzedData[[self getUniqueStr:NSStringFromClass([oriObj class])  sel:selStr]] = @(YES);
        }
    }
    
    
}

- (nullable NSString *)getUniqueStr:(NSString*)oriObjClass sel:(NSString*)sel
{
    if (!oriObjClass||!sel) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@_chd_hook_%@",oriObjClass,sel];
}


- (void)resetCHD_HoverView
{
    NSArray *WeakListViewArr = [[[CHD_HookHelper shareInstance].weakListViewDic keyEnumerator] allObjects];
    NSLog(@"当前listView个数：%@",@(WeakListViewArr.count));
    for (UIView *listView in WeakListViewArr) {
        if ([listView isKindOfClass:[UITableView class]] || [listView isKindOfClass:[UICollectionView class]]) {
            //先清空所有的CHD_HoverLabel
            [self showView:listView EveryView:^(UIView *subView) {
                if ([subView isKindOfClass:[CHD_HoverLabel class]]) {
                    [subView removeFromSuperview];
                }
            }];
            
            //清空后刷新当前listView
            [listView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            
            //刷新tableHederView、tableFooterView
            if ([listView isKindOfClass:[UITableView class]]) {
                UIView *tabelHeader = [(UITableView *)listView tableHeaderView];
                if (tabelHeader) {
                    [(UITableView *)listView setTableHeaderView:tabelHeader];
                }
                UIView *tableFooter = [(UITableView *)listView tableFooterView];
                if (tableFooter) {
                    [(UITableView *)listView setTableFooterView:tableFooter];
                }
            }
        }
    }
    
}



//遍历superView树
- (void)showView:(UIView*)superView EveryView:(void(^)(UIView*))Block
{
    if (!superView||!Block) {
        return;
    }
    
    NSMutableArray *QueueArr = @[superView].mutableCopy;
    
    while (QueueArr.count) {
        UIView *temp = [QueueArr firstObject];
        if (temp!=superView) {
            Block(temp);
        }
        [QueueArr removeObjectAtIndex:0];
        
        for (UIView* subV in temp.subviews) {
            [QueueArr addObject:subV];
        }
    }
}

@end


#pragma mark - CHD_MustrHelper
@implementation CHD_MustrHelper

+ (NSMutableAttributedString *)getMustr:(NSString*)str textColor:(UIColor *)textColor backGroundColor:(UIColor *)backColor
{
    NSMutableAttributedString *Mstr = [[NSMutableAttributedString alloc] initWithString:str];
    [Mstr addAttribute:NSBackgroundColorAttributeName value:backColor range:NSMakeRange(0, str.length)];
    [Mstr addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, str.length)];
    return Mstr;
}

@end




#pragma mark - UIView(CHD_HoverView)
@implementation UIView(CHD_HoverView)

- (UILabel *)hoverView:(UIColor*)borderColor
{
    __block CHD_HoverLabel *hover = nil;
    [[[self.subviews reverseObjectEnumerator] allObjects] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[CHD_HoverLabel class]]) {
            hover = (CHD_HoverLabel*)obj;
            *stop = YES;
        }
    }];
    
    
    if (!hover) {
        hover = [[CHD_HoverLabel alloc] initWithFrame:self.bounds];
        hover.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
        hover.layer.borderWidth = 1;
        hover.layer.borderColor = borderColor.CGColor;
        hover.textAlignment = NSTextAlignmentCenter;
        hover.adjustsFontSizeToFitWidth = YES;
        [self addSubview:hover];
        
        hover.translatesAutoresizingMaskIntoConstraints = YES;
        hover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        return hover;
    }else{
        [self bringSubviewToFront:hover];
        return hover;
    }
    
}
@end

@implementation CHD_HoverLabel

@end


#pragma mark - UITableView (CHD_Structure)
@implementation UITableView (CHD_Structure)
- (void)CHD_setDelegate:(id)delegate
{
    if (delegate) {
        
        NSArray *selArr = @[@"tableView:viewForHeaderInSection:",@"tableView:viewForFooterInSection:",@"tableView:heightForHeaderInSection:",@"tableView:heightForFooterInSection:"];
        
        [[CHD_HookHelper shareInstance] hookSelectors:selArr orginalObj:delegate swizzedObj:self];
        [[CHD_HookHelper shareInstance].weakListViewDic setObject:CHD_MapTable_Obj forKey:self];
    }
    [self CHD_setDelegate:delegate];
    
}
- (void)CHD_setDataSource:(id)dataSource
{
    if (dataSource) {
        NSArray *selArr = @[@"tableView:cellForRowAtIndexPath:"];
        
        [[CHD_HookHelper shareInstance] hookSelectors:selArr orginalObj:dataSource swizzedObj:self];
        [[CHD_HookHelper shareInstance].weakListViewDic setObject:CHD_MapTable_Obj forKey:self];
    }
    [self CHD_setDataSource:dataSource];
    
}


- (void)CHD_setTableHeaderView:(UIView *)tableHeaderView
{
    UILabel *headerHover = [tableHeaderView hoverView:chd_table_head_view_color];
    headerHover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"HeaderView--%@",NSStringFromClass([tableHeaderView class])] textColor:chd_table_text_color backGroundColor:chd_table_head_view_color];
    [self CHD_setTableHeaderView:tableHeaderView];
}
- (void)CHD_setTableFooterView:(UIView *)tableFooterView
{
    UILabel *footerHover = [tableFooterView hoverView:chd_table_footer_view_color];
    footerHover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"FooterView--%@",NSStringFromClass([tableFooterView class])] textColor:chd_table_text_color backGroundColor:chd_table_footer_view_color];
    [self CHD_setTableFooterView:tableFooterView];
}


-(UITableViewCell *)CHD_tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self CHD_tableView:tableView cellForRowAtIndexPath:indexPath];
    UILabel *hover = [cell hoverView:chd_table_cell_color];
    hover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"%@--%@--%@",NSStringFromClass([cell class]),@(indexPath.section),@(indexPath.row)] textColor:chd_table_text_color backGroundColor:[chd_table_cell_color colorWithAlphaComponent:chd_text_bg_alpha]];
    
    return cell;
}
- (UIView*)CHD_tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *secView = [self CHD_tableView:tableView viewForHeaderInSection:section];
    if ([secView isKindOfClass:[UILabel class]]) {
        [secView layoutIfNeeded];
    }
    UILabel *hover = [secView hoverView:chd_table_header_color];
    hover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"Header--%@--%@",NSStringFromClass([secView class]),@(section)] textColor:chd_table_text_color backGroundColor:[chd_table_header_color colorWithAlphaComponent:chd_text_bg_alpha]];
    
    return secView;
}
- (UIView*)CHD_tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *secView = [self CHD_tableView:tableView viewForFooterInSection:section];
    
    if ([secView isKindOfClass:[UILabel class]]) {
        [secView layoutIfNeeded];
    }
    UILabel *hover = [secView hoverView:chd_table_footer_color];
    hover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"Footer--%@--%@",NSStringFromClass([secView class]),@(section)] textColor:chd_table_text_color backGroundColor:[chd_table_footer_color colorWithAlphaComponent:chd_text_bg_alpha]];
    
    return secView;
}
- (CGFloat)CHD_tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self CHD_tableView:tableView heightForHeaderInSection:section];
}
- (CGFloat)CHD_tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self CHD_tableView:tableView heightForFooterInSection:section];
}


//为delegate实现默认的方法(处理返回高度却没有返回对应View的情况，不添加则无法显示header或footer)。   如果原类已实现下列方法，则会直接与原方法交换。
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [UIView new];
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //tableView.sectionHeaderHeight 系统默认值22，这里如果是22则认为开发者未设置此项。(如果想返回22,自己在delegate类中实现该回调方法即可)
    CGFloat headerH = tableView.sectionHeaderHeight;
    return headerH == 22.0f?0:headerH;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    //同上
    return tableView.sectionFooterHeight == 22.0f?0:tableView.sectionFooterHeight;
}


@end






//CollectionView
#pragma mark - UICollectionView (CHD_Structure)

static NSString *const CHD_Default_Collection_Header_Key = @"CHD_Default_Collection_Header";
static NSString *const CHD_Default_Collection_Footer_Key = @"CHD_Default_Collection_Footer";

//header
@interface CHD_Default_Collection_Header : UICollectionReusableView
@end

@implementation CHD_Default_Collection_Header
@end

//footer
@interface CHD_Default_Collection_Footer : UICollectionReusableView
@end

@implementation CHD_Default_Collection_Footer
@end

@implementation UICollectionView (CHD_Structure)

- (void)CHD_setDelegate:(id)delegate
{
    if (delegate) {
        NSArray *selArr = @[@"collectionView:layout:referenceSizeForFooterInSection:",@"collectionView:layout:referenceSizeForHeaderInSection:"];
        
        [[CHD_HookHelper shareInstance] hookSelectors:selArr orginalObj:delegate swizzedObj:self];
        [[CHD_HookHelper shareInstance].weakListViewDic setObject:CHD_MapTable_Obj forKey:self];
        [self registerClass:[CHD_Default_Collection_Header class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:CHD_Default_Collection_Header_Key];
        [self registerClass:[CHD_Default_Collection_Footer class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:CHD_Default_Collection_Footer_Key];
    }
    [self CHD_setDelegate:delegate];
}
- (void)CHD_setDataSource:(id)dataSource
{
    if (dataSource) {
        NSArray *selArr = @[@"collectionView:cellForItemAtIndexPath:",@"collectionView:viewForSupplementaryElementOfKind:atIndexPath:"];
        
        [[CHD_HookHelper shareInstance] hookSelectors:selArr orginalObj:dataSource swizzedObj:self];
        [[CHD_HookHelper shareInstance].weakListViewDic setObject:CHD_MapTable_Obj forKey:self];
        [self registerClass:[CHD_Default_Collection_Header class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:CHD_Default_Collection_Header_Key];
        [self registerClass:[CHD_Default_Collection_Footer class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:CHD_Default_Collection_Footer_Key];
    }
    [self CHD_setDataSource:dataSource];
}

- (__kindof UICollectionViewCell *)CHD_collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionViewCell *cell = [self CHD_collectionView:collectionView cellForItemAtIndexPath:indexPath];
    UILabel *hover = [cell hoverView:chd_collection_cell_color];
    hover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"%@++%@++%@",NSStringFromClass([cell class]),@(indexPath.section),@(indexPath.item)] textColor:chd_collection_text_color backGroundColor:[chd_collection_cell_color colorWithAlphaComponent:chd_collection_bg_alpha]];
    return cell;
}

- (UICollectionReusableView *)CHD_collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *sectionView = [self CHD_collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    UIColor *sectionViewColor = chd_collection_header_color;
    NSString *Kind = @"Header";
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        sectionViewColor = chd_collection_footer_color;
        Kind = @"Footer";
    }
    UILabel *hover = [sectionView hoverView:sectionViewColor];
    
    
    hover.attributedText = [CHD_MustrHelper getMustr:[NSString stringWithFormat:@"%@++%@++%@",Kind,NSStringFromClass([sectionView class]),@(indexPath.section)] textColor:chd_collection_text_color backGroundColor:[sectionViewColor colorWithAlphaComponent:chd_collection_bg_alpha]];
    return sectionView;
}


- (CGSize)CHD_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return [self CHD_collectionView:collectionView layout:collectionViewLayout referenceSizeForFooterInSection:section];
}
- (CGSize)CHD_collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return [self CHD_collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section];
}

//返回size为返回对应View时提供默认的Header，Footer.
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        return [(UICollectionViewFlowLayout*)collectionViewLayout headerReferenceSize];
    }
    return CGSizeZero;
    
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if ([collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        return [(UICollectionViewFlowLayout*)collectionViewLayout footerReferenceSize];
    }
    return CGSizeZero;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = CHD_Default_Collection_Header_Key;
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        identifier = CHD_Default_Collection_Footer_Key;
    }
    UICollectionReusableView *sectionView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:identifier forIndexPath:indexPath];
    
    return sectionView;
}
@end





