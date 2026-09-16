#import <Cocoa/Cocoa.h>

// Render architecture thumbnails without a browser or external dependencies.
static NSColor *Color(unsigned hex) {
    return [NSColor colorWithSRGBRed:((hex >> 16) & 255) / 255.0
                              green:((hex >> 8) & 255) / 255.0
                               blue:(hex & 255) / 255.0 alpha:1];
}
static void Box(CGFloat x, CGFloat y, CGFloat w, CGFloat h, unsigned fill, unsigned border) {
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(x, 560-y-h, w, h) xRadius:5 yRadius:5];
    [Color(fill) setFill];
    [path fill];
    if (border) { [Color(border) setStroke]; [path setLineWidth:1]; [path stroke]; }
}
static void Text(NSString *value, CGFloat x, CGFloat y, CGFloat w, CGFloat size, unsigned ink, BOOL bold, BOOL center) {
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.alignment = center ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:size weight:bold ? NSFontWeightSemibold : NSFontWeightRegular],
        NSForegroundColorAttributeName: Color(ink),
        NSParagraphStyleAttributeName: style
    };
    [value drawInRect:NSMakeRect(x, 560-y-44, w, 44) withAttributes:attributes];
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *output = argc > 1 ? @(argv[1]) : @"assets/portfolio";
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:output withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"%@", error); return 1;
        }
        NSArray *diagrams = @[
            @[@"daily-question", @[@"동시 요청 A / B", @"오늘 이력 없음", @"각각 신규 발급"], @[@"사용자별 Lock", @"최신 이력 재조회", @"기존 반환 / 발급"], @"동일한 발급 판단이 중복 실행", @"조회부터 저장까지 보호 · Commit 후 락 해제", @NO],
            @[@"report-notification", @[@"신고 저장", @"Slack 전송 실패", @"알림 누락"], @[@"신고 Commit", @"Outbox + 전송", @"실패 건 재처리"], @"실패한 전송을 다시 찾을 기록이 없음", @"PENDING → SUCCESS / FAILED → Scheduler", @NO],
            @[@"coupon-consistency", @[@"동시 요청 A / B", @"같은 재고 조회", @"각각 발급 진행"], @[@"Redisson Lock", @"조건부 재고 차감", @"UNIQUE 발급"], @"재고 초과 · 사용자별 중복 발급 가능", @"Redis는 경합 제어 · DB는 정합성 보호", @YES],
            @[@"popular-query", @[@"좋아요 100만 건", @"실시간 집계·정렬", @"Top 20 조회"], @[@"쓰기 시 집계 갱신", @"메타 + 인덱스", @"Top 20 조회"], @"조회할 때마다 GROUP BY + COUNT + ORDER BY", @"읽기 경로에서 반복 집계 제거", @YES]
        ];
        for (NSArray *diagram in diagrams) {
            NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:1000 pixelsHigh:560 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap]];
            Box(0, 0, 1000, 560, 0xf7f8f9, 0);
            BOOL blue = [diagram[5] boolValue];
            unsigned accent = blue ? 0x375d94 : 0x22695c;
            unsigned soft = blue ? 0xeef3fa : 0xedf5f1;
            for (int row = 0; row < 2; row++) {
                CGFloat top = row == 0 ? 48 : 298;
                Text(row == 0 ? @"BEFORE" : @"AFTER", 48, top, 880, 18, row == 0 ? 0x9b4949 : accent, YES, NO);
                NSArray *labels = diagram[row + 1];
                for (int i = 0; i < 3; i++) {
                    CGFloat x = 48 + i * 310;
                    Box(x, top + 48, 284, 90, row == 0 ? 0xffffff : soft, 0xd5dee0);
                    Text(labels[i], x + 6, top + 75, 272, 24, row == 0 ? 0x454c51 : accent, YES, YES);
                    if (i < 2) Text(@"→", x + 287, top + 75, 22, 22, 0x7e898e, NO, YES);
                }
                Text(diagram[row + 3], 48, top + 159, 900, 20, 0x626b70, NO, NO);
            }
            Box(48, 265, 904, 1, 0xdde2e3, 0);
            [NSGraphicsContext restoreGraphicsState];
            NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            NSString *path = [output stringByAppendingPathComponent:[diagram[0] stringByAppendingString:@".png"]];
            if (![png writeToFile:path options:NSDataWritingAtomic error:&error]) { NSLog(@"%@", error); return 1; }
            NSLog(@"Rendered %@", diagram[0]);
        }
    }
    return 0;
}
