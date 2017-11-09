function lineProfile(img)
imagesc(img);
c = improfile();
c = squeeze(c);
plot(c);
end