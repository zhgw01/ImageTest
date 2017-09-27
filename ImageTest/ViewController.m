//
//  ViewController.m
//  ImageTest
//
//  Created by zhang gongwei on 17/9/24.
//  Copyright © 2017年 AIMI Network Technology Co., Ltd. All rights reserved.
//

#import "ViewController.h"

#import "turbojpeg.h"
#import "jpeglib.h"
#import "jerror.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *outputImageView;

@property (strong, nonatomic) UIImage *image;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.image = [UIImage imageNamed:@"wechat.jpg"];
    self.imageView.image = self.image;
}


- (IBAction)onSave:(id)sender {
    
    
    UIImage *output = self.image;
    UIImage *output2;
    
    @autoreleasepool {
        CGFloat quality = 0.75;
        NSData *data = [self jpegData:output quality:quality];
        NSLog(@"data size: %ld k", data.length / 1024);
        output = [UIImage imageWithData:data];
        
        NSString *path = [[self cachePath] stringByAppendingPathComponent:@"turbo.jpg"];
        [data writeToFile:path atomically:YES];
        
        NSData *data2 = UIImageJPEGRepresentation(self.image, quality);
        path = [[self cachePath] stringByAppendingPathComponent:@"sys.jpg"];
        [data2 writeToFile:path atomically:YES];
        
        output2 = [UIImage imageWithData:data2];
        NSLog(@"data2 size: %ld k", data2.length / 1024);
    }

    self.outputImageView.image = output;
    
}

- (NSString *)cachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    NSError *error;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    return cachePath;
}


- (NSData *)jpegData:(UIImage *)image quality:(CGFloat)quality {
    
    CGImageRef imageRef = image.CGImage;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    if (!colorSpace) {
        return nil;
    }
    
    unsigned char *rawData = malloc(height * bytesPerRow);
    if (!rawData) {
        return nil;
    }

    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow,
                                                 colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
    if (!context) {
        CGContextRelease(context);
        return nil;
    }
 
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    if (!rawData) {
        return nil;
    }
    
    // encode jpeg
    long unsigned int jpegSize = 0;
    unsigned char* compressedImage = NULL;
    tjhandle jpegCompressor = tjInitCompress();
    
    if (!jpegCompressor) {
        free(rawData);
        return nil;
    }
    
    tjCompress2(jpegCompressor, rawData, (int)width, 0, (int)height, TJPF_ARGB,
                &compressedImage, &jpegSize, TJSAMP_444, quality * 100,
                TJFLAG_FASTDCT);
    
        
    free(rawData);
    tjDestroy(jpegCompressor);
    
    if (!jpegCompressor) {
        return nil;
    }
    
    NSData* data = [NSData dataWithBytes:compressedImage length:jpegSize];
    tjFree(compressedImage);
    
    return data;
}

- (NSData *)jpegData2:(UIImage *)image quality:(CGFloat)quality {
    
    CGImageRef imageRef = image.CGImage;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    if (!colorSpace) {
        return nil;
    }
    
    unsigned char *rawData = malloc(height * bytesPerRow);
    if (!rawData) {
        return nil;
    }
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow,
                                                 colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
    if (!context) {
        CGContextRelease(context);
        return nil;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    if (!rawData) {
        return nil;
    }
    
    // encode jpeg
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    
    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    

    int components = 4;
    cinfo.image_width = (int)width;
    cinfo.image_height = (int)height;
    cinfo.in_color_space = JCS_EXT_ARGB;
    cinfo.input_components = components;
    jpeg_set_defaults(&cinfo);
    
    //default is 75
    jpeg_set_quality(&cinfo, quality * 100, TRUE);
    
    unsigned char *outbuffer = NULL;
    unsigned long outsize = 0;
    jpeg_mem_dest(&cinfo, &outbuffer, &outsize);
    
    jpeg_start_compress(&cinfo, TRUE);
    
    int row_stride = cinfo.image_width * components;
    JSAMPROW row_pointer[1];
    
    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = & rawData[cinfo.next_scanline * row_stride];
        (void) jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }
    
    jpeg_finish_compress(&cinfo);
    
    NSData* data = nil;
    
    if (outbuffer) {
        data = [NSData dataWithBytes:outbuffer length:outsize];
        free(outbuffer);
    }
    
    free(rawData);
    jpeg_destroy_compress(&cinfo);
    
    return data;
}

@end
